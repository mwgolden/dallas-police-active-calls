/*
    Get all active calls
*/
with src as (
    select *
        ,rank() over(partition by call_id order by cast(update_date as timestamp) desc) as r
    from change_history
    where call_id not in (
        select call_id
        from change_history
        where change_type = 'delete'
    )
)
select *
from src where r = 1