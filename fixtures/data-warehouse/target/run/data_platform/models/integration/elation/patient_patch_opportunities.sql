
  
    

create or replace transient table dw_dev.dev_jkizer.patient_patch_opportunities
    copy grants
    
    
    as (with distinct_ids as (
    select suvida_id
    from dw_dev.dev_jkizer.patient_active_eligibility_tag_status

    union all

    select suvida_id
    from dw_dev.dev_jkizer.patient_high_risk_tag_status

    union all

    select suvida_id
    from dw_dev.dev_jkizer.patient_insurance_sync_opportunities
    
    union all 

    select suvida_id
    from dw_dev.dev_jkizer.patient_overall_high_risk_tag_status
    
    union all
    
    select suvida_id
    from dw_dev.dev_jkizer.patient_dsnp_tag_status
)

select distinct
    di.suvida_id,
    pt.elation_id,
    paets.should_have_tag as should_have_active_tag,
    paets.has_active_tag,
    case
        when paets.is_active_assignment is null and paets.has_active_tag is null then 'None'
        else 'Update'
    end as active_tag_action,
    phrts.should_have_tag as should_have_risk_level_tag,
    phrts.has_matching_risk_level_tag,
    phrts.unplanned_admission_risk_level as risk_level_tag_value,
    case
        when phrts.suvida_id is null or phrts.elation_id is null then 'None'
        when phrts.should_have_tag = 1 and phrts.has_risk_level_tag = 1 and phrts.has_matching_risk_level_tag = 1 then 'None'
        when phrts.should_have_tag = 0 and phrts.has_risk_level_tag = 0 then 'None'
        else 'Update'
    end as risk_level_tag_action,
    piso.payer_member_id as member_id,
    emr_plan_name,
    emr_carrier_id,
    emr_carrier_name,
    emr_plan_id,
    piso.address as emr_carrier_address,
    piso.city as emr_carrier_city,
    piso.state as emr_carrier_state,
    piso.zip_code as emr_carrier_zip,
    case
        when emr_plan_name is null then 'None'
        else 'Update'
    end as insurance_action,
    pohr.should_have_tag as should_have_high_risk_tag,
    pohr.has_risk_level_tag as has_high_risk_tag,
    case 
        when pohr.should_have_tag = 1 and pohr.has_risk_level_tag = 1 then 'None'
        when pohr.should_have_tag = 0 and pohr.has_risk_level_tag = 0 then 'None'
        when pohr.should_have_tag is null or pohr.has_risk_level_tag is null then 'None'
        else 'Update'
    end as active_high_risk_tag_action,
    pdt.should_have_tag as should_have_dsnp_tag,
    pdt.has_dsnp_tag as has_dsnp_tag,
    case
        when pdt.should_have_tag = 1 and pdt.has_dsnp_tag = 1 then 'None'
        when pdt.should_have_tag = 0 and pdt.has_dsnp_tag = 0 then 'None'
        when pdt.should_have_tag is null or pdt.has_dsnp_tag is null then 'None'
        else 'Update'
    end as dsnp_tag_action,
from distinct_ids di
left join dw_dev.dev_jkizer.dim_patient pt
    on di.suvida_id = pt.suvida_id
left join dw_dev.dev_jkizer.patient_active_eligibility_tag_status paets
    on di.suvida_id = paets.suvida_id
left join dw_dev.dev_jkizer.patient_high_risk_tag_status phrts
    on di.suvida_id = phrts.suvida_id
left join dw_dev.dev_jkizer.patient_insurance_sync_opportunities piso
    on di.suvida_id = piso.suvida_id
left join dw_dev.dev_jkizer.patient_overall_high_risk_tag_status pohr 
    on di.suvida_id = pohr.suvida_id
left join dw_dev.dev_jkizer.patient_dsnp_tag_status pdt
    on di.suvida_id = pdt.suvida_id
    )
;


  