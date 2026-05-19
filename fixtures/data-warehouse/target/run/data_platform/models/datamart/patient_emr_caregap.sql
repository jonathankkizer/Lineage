
  
    

create or replace transient table dw_dev.dev_jkizer.patient_emr_caregap
    copy grants
    
    
    as (select 
    siw.suvida_id,
    cg.caregaps_id,
    cgd.description,
    replace(replace(cgd.name, 'Assess: ', ''), 'SVHQ: ', '') as caregap_name,
    case
        when cgd.name like '%Patient is non adherent%' then 'Medication Adherence'
        when cgd.name like '%Assess%' then 'HCC Risk Coding'
        when cgd.name like '%SVHQ%' then 'Quality'
        else 'Other'
    end as caregap_name_group,
    date(cg.created_timestamp) as created_date,
    date(cg.closed_date) as closed_date,
    datediff(day, date(cg.created_timestamp), date(cg.closed_date)) as caregap_elapsed,
    cg.closed_by,
    cg.status,
    case when cg.status = 'closed' then 1 else 0 end as is_closed,
    case when cg.status = 'open' then 1 else 0 end as is_open,
from dw_dev.dev_jkizer_staging.stg_elation_caregap_definitions cgd
inner join dw_dev.dev_jkizer_staging.stg_elation_caregaps cg 
    on cgd.definition_id = cg.definition_id
left join dw_dev.dev_jkizer.suvida_id_walk siw
    on cg.patient_id = siw.member_id
    and siw.source = 'Elation'
    )
;


  