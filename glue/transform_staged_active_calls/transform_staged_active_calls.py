import sys
import datetime
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

spark.conf.set('spark.sql.sources.partitionOverwriteMode','dynamic')

FULL_REFRESH = False

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

# Get new versions of rows
newest_download_df = (tx_df
                .select('incident_number', 'unit_number', 'download_datetime')
                .groupBy('incident_number', 'unit_number')
                .agg(
                    F.max('download_datetime').alias('download_datetime')
                )
            )

newest_download_df = newest_download_df.withColumn('partition_key', F.to_date('download_datetime'))
# Produce data frame with most recent row versions
final_df = (tx_df
                .join(newest_download_df, ['incident_number', 'unit_number', 'download_datetime'])
           )

if FULL_REFRESH:
    (final_df
        .write
        .mode('overwrite')
        .format('parquet')
        .partitionBy('partition_key')
        .save('s3://com.wgolden.dallas-police-active-calls/transformed/'))
else:
    # Define partitions for update/insert >= previous day
    # this will reduce the number of files overwritten
    end_date = datetime.datetime.now()
    start_date = end_date - datetime.timedelta(days=1)
    date_format = '%Y-%m-%d'
    start_partition = start_date.strftime(date_format)
    end_partition = end_date.strftime(date_format)

    existing_df = spark.read.parquet(
        f"s3://com.wgolden.dallas-police-active-calls/transformed/partition_key={start_partition}/",
        f"s3://com.wgolden.dallas-police-active-calls/transformed/partition_key={end_partition}/"
    ).withColumn('partition_key', F.to_date('download_datetime'))

    updates_df = final_df.where(f"partition_key >= '{start_partition}'")
    merged_df = (
        existing_df.alias('existing')
            .join(
                updates_df.alias('new'), ['incident_number', 'unit_number'], 'outer'
            )
            .select(
                *[F.coalesce('new.' + col, 'existing.' + col).alias(col) for col in updates_df.columns]
            )
    )

    (merged_df
        .write
        .mode('overwrite')
        .format('parquet')
        .partitionBy('partition_key')
        .save('s3://com.wgolden.dallas-police-active-calls/transformed/'))