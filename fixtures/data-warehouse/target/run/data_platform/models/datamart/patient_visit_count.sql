
  
    

create or replace transient table dw_dev.dev_jkizer.patient_visit_count
    copy grants
    
    
    as (select 
    suvida_id, 
    replace(encounter_service_type, 'is_', '') as encounter_service_type, 
    sum(encounter_service_value) as encounter_service_count,
    case
       when sum(encounter_service_value) = 0 then '0 visits'
       when sum(encounter_service_value) = 1 then '1 visit'
       when sum(encounter_service_value) between 2 and 4 then '2-4 visits'
       else '4+ visits'
    end as visit_category
from dw_dev.dev_jkizer.patient_encounter pe
     unpivot (
        encounter_service_value for encounter_service_type in (is_rd, is_ultrasound, is_xray, is_pcp, is_mh, is_pt, is_guia, is_rn)
) as unpivoted_data
where encounter_type != 'non_visit_encounter'
group by suvida_id, replace(encounter_service_type, 'is_', '')
    )
;


  