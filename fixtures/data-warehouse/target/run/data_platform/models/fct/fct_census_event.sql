
  
    

create or replace transient table dw_dev.dev_jkizer.fct_census_event
    copy grants
    
    
    as (with aggregate_census_data as (
    select 
        suvida_id, 
        admit_date, 
        level_of_care, 
        facility,
	    max(attending_physician) as attending_physician,
	    max(discharge_date) as discharge_date,
	    min(earliest_report_date) as earliest_report_date,
        min(earliest_discharge_report_date) as earliest_discharge_report_date,
        max(max_report_date) as max_report_date,
        min(dx_code) as dx_code,
        min(dx_text) as dx_text,
	    max(payor_flag) as payor_flag,
	    max(hie_flag) as hie_flag,
	    listagg(distinct source,' | ') as data_sources,
        listagg(distinct source_type, ' | ') as data_source_types,
    from dw_dev.dev_jkizer.intmdt_census_event
    where suvida_id is not null and admission_order_desc = 1
    group by suvida_id, admit_date, level_of_care, facility
)
select 
    md5(cast(coalesce(cast(acd.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(acd.admit_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(acd.level_of_care as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(acd.facility as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as census_event_id,
    acd.suvida_id,
    acd.admit_date,
    acd.level_of_care,
    acd.facility,
    acd.attending_physician,
    acd.discharge_date,
    acd.earliest_report_date,
    acd.earliest_discharge_report_date,
    acd.max_report_date,
    acd.dx_code,
    acd.dx_text,
    acd.payor_flag,
    acd.hie_flag,
    acd.data_sources,
    acd.data_source_types,
from aggregate_census_data acd
    )
;


  