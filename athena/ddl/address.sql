CREATE EXTERNAL TABLE IF NOT EXISTS dpd_active_Calls.address (
  address_id string,
  addresses string,
  expires_on double
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '|'
STORED AS TEXTFILE
LOCATION 's3://com.wgolden.dallas-police-active-calls/updates/locations/'
TBLPROPERTIES ('skip.header.line.count'='1');