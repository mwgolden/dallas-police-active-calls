with src as (
    select 
        incident_number,
        division,
        nature_of_call,
        priority,
        date(
            from_iso8601_timestamp(date)
        ) as incident_date,
        time as incident_time, 
        unit_number,
        block,
        location,
        beat,
        reporting_area,
        status,
        date_add(
            'hour',
            5,
            parse_datetime(download_date, 'yyyy-MM-dd HH:mm') at time zone 'America/Chicago'
        ) as download_date
    from stage
)
select *
from src
where (incident_number, unit_number, download_date) in (
    select incident_number, unit_number, max(download_date) download_date
    from src
    group by incident_number, unit_number
)
order by download_date asc