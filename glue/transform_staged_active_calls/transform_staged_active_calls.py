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
            F.trim('incident_number').alias('incident_nbumber'), 
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

tx_df.show()