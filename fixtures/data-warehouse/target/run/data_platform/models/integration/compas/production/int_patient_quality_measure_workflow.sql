
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_quality_measure_workflow
    copy grants
    
    
    as (select distinct
    atw.quality_measure_skey,
    r.workflow_status,
    atw.workflow_status_detail,
    atw.workflow_note,
    atw.workflow_status_index,
    atw.last_modified_by_name,
    atw.last_modified_by_email,
    atw.last_modified_datetime,
    atw.workflow_attachment
from dw_dev.dev_jkizer_staging.stg_airtable_workflow_part_c atw
left join dw_dev.dev_jkizer_source.map_quality_workflow_rollup r
	on atw.workflow_status_detail = r.workflow_status_detail
left join dw_dev.dev_jkizer.int_patient_quality_measure qms
    on atw.quality_measure_skey = qms.quality_measure_skey
where
    qms.quality_measure_skey is not null
    )
;


  