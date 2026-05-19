
  
    

create or replace transient table dw_dev.dev_jkizer.dim_date
    copy grants
    
    
    as (select
	date_id,
	date_day,
	date_week,
	date_month,
	date_quarter,
	date_year,
	calendar_year,
	calendar_month,
	calendar_week,
	fiscal_year,
	fiscal_month,
	fiscal_week,
	day_of_month,
	day_of_week,
	is_bow,
	is_bom,
	is_eow,
	is_eom,
	calendar_quarter,
	fiscal_quarter,
	is_weekend,
	is_holiday,
	is_workday
from dw_dev.dev_jkizer_staging.stg_dim_date
    )
;


  