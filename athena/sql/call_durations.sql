select 
    call_id
    ,max(date_add('hour', -5, cast(update_date as timestamp))) as update_datetime
    ,date_diff(
        'minute',
        min(cast(concat(substring(date,1,10), ' ',time) as timestamp)),
        max(date_add('hour', -5, cast(update_date as timestamp)))
    ) call_duration_minutes
from change_history
group by call_id