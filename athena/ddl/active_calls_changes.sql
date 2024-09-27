CREATE EXTERNAL TABLE IF NOT EXISTS change_history (
    call_id STRING,
    update_date STRING,
    address_id STRING,
    beat STRING,
    block STRING,
    change_type STRING,
    `date` STRING,
    division STRING,
    expires_on STRING,
    incident_number STRING,
    `location` STRING,
    nature_of_call STRING,
    priority STRING,
    reporting_area STRING,
    status STRING,
    `time` STRING,
    unit_number STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = '|',
    'quoteChar' = '\"',
    'escapeChar' = '\\'
)
LOCATION 's3://com.wgolden.dallas-police-active-calls/updates/active_calls/'
TBLPROPERTIES ('has_encrypted_data'='false',
    'skip.header.line.count' = '1');
