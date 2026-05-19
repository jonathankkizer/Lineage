
  
    

create or replace transient table dw_dev.dev_jkizer.patient_insurance_sync_opportunities
    copy grants
    
    
    as (with active_eligible_patients as (
    select
        ps.suvida_id,
        ps.elation_id,
        ps.payer_member_id,
        ps.payer_name,
        pn.plan_group,
        ps.payer_plan_code,
        ps.payer_plan_name,
        pn.emr_plan_name,
        pn.emr_carrier_id,
        pn.emr_plan_id,
        pn.address,
        pn.city,
        pn.state,
        pn.zip_code
    from dw_dev.dev_jkizer.patient_summary ps
    left join dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_code pc
        on ps.payer_plan_code = pc.formatted_plan_code
    left join dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_name pn
        on pc.unique_plan_code = pn.plan_code and
           pn._rn = 1
    where
        is_active_assignment = 1 and
        pn.plan_year = year(current_timestamp())
),

patient_elation_insurance as (
    select *
    from dw_dev.dev_jkizer_staging.stg_elation_patient_insurance
    where
        _is_deleted_record = FALSE and
        insurance_rank = 1 and
        insurance_company_id not in (
            540205905609070,
            613602819834222,
            696366094221678
        )
)

select
    suvida_id,
    elation_id,
    payer_member_id,
    payer_name,
    payer_plan_code,
    plan_group as emr_carrier_name,
    emr_carrier_id,
    emr_plan_name,
    emr_plan_id,
    address,
    city,
    state,
    zip_code
from active_eligible_patients aep
left join patient_elation_insurance ins
    on aep.elation_id = ins.patient_id and
    (
        (aep.emr_carrier_id = ins.insurance_company_id and aep.emr_plan_name = ins.insurance_plan) or
        (aep.plan_group = ins.insurance_name and aep.emr_plan_name = ins.insurance_plan) or 
        (aep.emr_plan_name = ins.insurance_plan)
    )
where ins.patient_id is null
    )
;


  