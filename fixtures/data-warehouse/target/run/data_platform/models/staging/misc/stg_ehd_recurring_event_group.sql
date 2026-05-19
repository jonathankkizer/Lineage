
  create or replace   view dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
  
  copy grants
  
  
  as (
    select
	src.id,
	src.practice,
	src.reason,
	src.time_slot_type,
	src.is_blocking,
	to_date(src.created_date) as created_date,
	to_date(src.deleted_date::varchar) as deleted_date,
	f.value:id::number as schedule_id,
	f.value:created_date::string as schedule_created_date,
	trim(f.value:description::string, ' \t\n\r\v\f\u2003') as schedule_description,
	f.value:event_time::string as event_time,
	f.value:duration::number as event_duration,
	f.value:physician::number as physician_id,
	f.value:series_start::string as series_start,
	f.value:series_stop::string as series_stop,
	f.value:repeats::string as repeat_interval,
	f.value:dow_monday::boolean as dow_monday,
	f.value:dow_tuesday::boolean as dow_tuesday,
	f.value:dow_wednesday::boolean as dow_wednesday,
	f.value:dow_thursday::boolean as dow_thursday,
	f.value:dow_friday::boolean as dow_friday,
	f.value:dow_saturday::boolean as dow_saturday,
	f.value:dow_sunday::boolean as dow_sunday
from source_prod.misc.src_ehd_recurring_event_groups_json as src,
lateral flatten(input => parse_json(src.schedules)) as f
  );

