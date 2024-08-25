create external table if not exists  stage (
    incident_number string, 
    division string,
    nature_of_call string,
    priority string,
    date string,
    time string,
    unit_number string,
    block string,
    location string,
    beat string,
    reporting_area string,
    status string,
    download_date string
)
row format serde 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
with serdeproperties (
    'field.delim' = '|',
    'serialization.format' = '|'
)
location 's3://<path>'
TBLPROPERTIES (
    'skip.header.line.count' = '1',
    'has_encrypted_data'='false'
);