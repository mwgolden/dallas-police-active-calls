create external table if not exists transformed (
    incident_number string, 
    division string,
    nature_of_call string,
    priority integer,
    unit_number string ,
    block string,
    location string,
    beat string,
    reporting_area string,
    status string,
    incident_datetime timestamp,
    download_datetime timestamp
)
stored as parquet
location 's3://com.wgolden.dallas-police-active-calls/transformed/'
tblproperties (
    'parquet.timestamp.time.zone' = 'CST'
)