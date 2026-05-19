
  
    

create or replace transient table dw_dev.dev_jkizer.patient_hcc_coding_gap
    copy grants
    
    
    as (with latest_coding as (
    select
        gap.suvida_id,
        dim.elation_id,
        member_id,
        measure_year,
        hcc_category,
        hcc_description,
        hl.hcc_community_factor,
        hl.hcc_label,
        icd_10_code,
        measure_status,
        measure_detail,
        report_date,
        measure_source,
        variant_id,
        coding_measure_skey,
        case 
            when measure_status = 'closed' then 1
            when measure_status = 'suspect' then 2
            when measure_status = 'open' then 3
            when measure_status = 'NOT REPORTED' then 4
            else 5 
        end as measure_status_weight,
    from dw_dev.dev_jkizer.fct_coding_measure gap
    inner join dw_dev.dev_jkizer.dim_patient dim 
        on gap.suvida_id = dim.suvida_id
    left join dw_dev.dev_jkizer_staging.stg_elation_hcc_lookup hl
        on hcc_category = concat('HCC', hl.hcc_code)
        and hl.version = 2023
    qualify row_number() over (partition by gap.suvida_id, gap.hcc_category, gap.measure_year order by report_date desc) = 1 -- grab latest data only
), hcc_bump as (
    select
        coding_measure_skey,
        max(iff(fhd.suvida_id is null, false, true)) as is_emr_claims_hcc_diagnosis_complete,
    from latest_coding lc
    inner join dw_dev.dev_jkizer.fct_patient_hcc_diagnosis fhd
        on lc.suvida_id = fhd.suvida_id
        and concat('HCC', lc.hcc_category) = fhd.hcc_code
        and fhd.source_type = 'emr_claims'
        and fhd.is_max_monthly_period = true
        and fhd.hcc_model = 24
        and fhd.period_type = 'monthly'
    where lc.hcc_category != 'HCC19'
    group by coding_measure_skey
    
    union all
    /* trumping logic for diabetes with and without chronic complications */
    select
        coding_measure_skey,
        max(iff(fhd.suvida_id is null, false, true)) as is_emr_claims_hcc_diagnosis_complete,
    from latest_coding lc
    inner join dw_dev.dev_jkizer.fct_patient_hcc_diagnosis fhd
        on lc.suvida_id = fhd.suvida_id
        and fhd.hcc_code in ('HCC19', 'HCC18')
        and fhd.source_type = 'emr_claims'
        and fhd.is_max_monthly_period = true
        and fhd.hcc_model = 24
        and fhd.period_type = 'monthly'
    where lc.hcc_category = 'HCC19'
    group by coding_measure_skey
)
select
    lc.*,
    coalesce(hb.is_emr_claims_hcc_diagnosis_complete, false) as is_emr_claims_hcc_diagnosis_complete,
from latest_coding lc
left join hcc_bump hb 
    using(coding_measure_skey)
where measure_status = 'open'
    )
;


  