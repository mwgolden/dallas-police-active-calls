import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

import pyspark.sql.functions as F
import pyspark.sql.types as T

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

active_calls_dynf = glueContext.create_dynamic_frame.from_catalog(database='dpd_active_calls', table_name='stage')
active_calls_df = active_calls_dynf.toDF()

tx_df = (active_calls_df
     .withColumn('incident_datetime', F.to_timestamp(F.concat_ws(' ', F.substring('date', 1, 10), 'time')))
     .withColumn('download_datetime', F.to_timestamp('download_date'))
     .drop('date')
     .drop('time')
     .drop('download_date')
      .select(
            F.trim('incident_number').alias('incident_number'), 
            F.trim('division').alias('division'),
            F.trim('nature_of_call').alias('nature_of_call'),
            F.trim('priority').cast('int').alias('priority'),
            F.trim('unit_number').alias('unit_number'),
            F.trim('block').alias('block'),
            F.trim('location').alias('location'),
            F.trim('beat').alias('beat'),
            F.trim('reporting_area').alias('reporting_area'),
            F.trim('status').alias('status'),
            'incident_datetime',
            'download_datetime'
     )
)

# Get most recent versions of rows
recent_df = (tx_df
                .select('incident_number', 'unit_number', 'download_datetime')
                .groupBy('incident_number', 'unit_number')
                .agg(
                    F.max('download_datetime').alias('download_datetime')
                )
            )

recent_df = recent_df.withColumn('partition_key', F.to_date('download_datetime'))
# Produce data frame with most recent row versions
final_df = (tx_df
                .join(recent_df, ['incident_number', 'unit_number', 'download_datetime'])
           )

from awsglue.dynamicframe import DynamicFrame

transformed_calls_dynf = glueContext.create_dynamic_frame.from_catalog(database='dpd_active_calls', table_name='transformed')
transformed_calls_dynf = transformed_calls_dynf.toDF()


dyf = DynamicFrame.fromDF(final_df, glueContext, 'convert_to_dynamic_frame')

glueContext.write_dynamic_frame.from_options(
    frame=dyf,
    connection_type='s3',
    connection_options={
        "path": 's3://com.wgolden.dallas-police-active-calls/transformed/',
        "partitionKeys": ['partition_key']
    },
    format='parquet',
    format_options={
        "compression": "gzip"
    },
    transformation_ctx='write_s3_parquet'
)