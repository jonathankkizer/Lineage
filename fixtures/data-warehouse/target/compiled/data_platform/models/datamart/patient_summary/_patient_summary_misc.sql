

-- Component: Miscellaneous patient attributes (transportation, tags, advance planning, MLR, etc.)
-- Extracted from patient_summary to reduce model complexity

with transportation_flag as (
    select
        fd.suvida_id,
        max(transportation_grouping) as transportation_flag,
        max(iff(mtd.diagnosis_grouping in ('Serious Mental Illness','Advanced Illness'), mtd.diagnosis_grouping, null)) as transportation_disability_desc
    from dw_dev.dev_jkizer.fct_diagnosis fd
    inner join dw_dev.dev_jkizer_source.map_transportation_diagnosis mtd
        on replace(fd.icd_10_code, '.', '') = replace(mtd.icd_10_code, '.', '')
    where diagnosis_date >= dateadd(month, -12, current_date())
    and transportation_grouping is not null
    group by 1
),

tag_list as (
    select
        suvida_id,
        listagg(tag_value, ' | ') as active_tag_list,
        max(dg.guia_name) as assigned_guia_name
    from dw_dev.dev_jkizer.fct_patient_tag fpt
    left join dw_dev.dev_jkizer.dim_guia dg
        on fpt.tag_value = dg.tag_guia_role_name
    where is_active_tag = true
    group by 1
),

rolling_12_mlr as (
    select
        pr.suvida_id,
        sum(mmr_revenue) as mmr_revenue,
        sum(pcms.total_paid) as total_claims_cost,
        div0null(sum(pcms.total_paid), sum(mmr_revenue)) as rolling_12_operational_mlr
    from dw_dev.dev_jkizer.patient_revenue pr
    inner join dw_dev.dev_jkizer.patient_claim_monthly_spend pcms
        on pr.suvida_id = pcms.suvida_id
        and pr.mmr_month = pcms.date_month
    where pr.mmr_month <= dateadd(month, -3, date_trunc(month, current_date()))
    and pr.mmr_month >= dateadd(month, -15, date_trunc(month, current_date()))
    group by all
),

advance_planning as (
    select
        suvida_id,
        case when is_advance_care_plan = 1 then CREATION_DATETIME end as advance_care_plan_document_attached_datetime,
        is_advance_care_plan as advance_care_plan_document_attached
    from dw_dev.dev_jkizer.fct_elation_report
    where is_advance_care_plan = 1
    qualify row_number() over(partition by suvida_id order by CREATION_DATETIME desc) = 1
),

pre_visit_coder_review as (
    select
        suvida_id,
        1 as has_pre_visit_coder_review_ytd
    from dw_dev.dev_jkizer.fct_coder_attestation_diagnosis
    where coder_attestation_opportunity_index = 1
        and measure_year = year(current_date())
    group by suvida_id
),

-- ======================================== --
--             Falls Metrics
-- ======================================== --
fall_flags as (
    select distinct mc.encounter_id
    from dw_dev.dev_jkizer_staging.stg_claims_expanded_diagnosis dx
    join dw_dev.dev_jkizer_staging.stg_medical_claim mc
        on dx.claim_id = mc.claim_id
        and dx.data_source = mc.data_source
    where left(dx.icd_10_code, 3) between 'W00' and 'W19'
       or dx.icd_10_code like 'R296%'
       or dx.icd_10_code like 'Z9181%'
),

er_fall_encounters as (
    select
        er.suvida_id,
        count(distinct case when ff.encounter_id is not null then er.encounter_id end) as rolling_12_fall_er_visits
    from dw_dev.dev_jkizer.patient_claim_er er
    left join fall_flags ff on er.encounter_id = ff.encounter_id
    where er.encounter_start_date >= dateadd(month, -12, current_date)
    group by 1
),

ip_fall_encounters as (
    select
        ip.suvida_id,
        count(distinct case when ff.encounter_id is not null then ip.encounter_id end) as rolling_12_fall_ip_visits
    from dw_dev.dev_jkizer.patient_claim_inpatient ip
    left join fall_flags ff on ip.encounter_id = ff.encounter_id
    where ip.encounter_start_date >= dateadd(month, -12, current_date)
    group by 1
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    coalesce(tf.transportation_flag, 'rideshare') as transportation_flag,
    tf.transportation_disability_desc,
    iff(lower(tl.active_tag_list) like '%hrh%', true, false) as is_active_hrh_tag,
    tl.active_tag_list,
    tl.assigned_guia_name,
    mlr.rolling_12_operational_mlr,
    mlr.mmr_revenue as rolling_12_operational_mmr_revenue,
    mlr.total_claims_cost as rolling_12_operational_claims_cost,
    coalesce(apr.advance_care_plan_document_attached, 0) as advance_care_plan_document_attached,
    apr.advance_care_plan_document_attached_datetime,
    coalesce(pvcr.has_pre_visit_coder_review_ytd, 0) as has_pre_visit_coder_review_ytd,
    coalesce(er.rolling_12_fall_er_visits, 0) as rolling_12_fall_er_visits,
    coalesce(ip.rolling_12_fall_ip_visits, 0) as rolling_12_fall_ip_visits
from all_patients ap
left join transportation_flag tf on ap.suvida_id = tf.suvida_id
left join tag_list tl on ap.suvida_id = tl.suvida_id
left join rolling_12_mlr mlr on ap.suvida_id = mlr.suvida_id
left join advance_planning apr on ap.suvida_id = apr.suvida_id
left join pre_visit_coder_review pvcr on ap.suvida_id = pvcr.suvida_id
left join er_fall_encounters er on ap.suvida_id = er.suvida_id
left join ip_fall_encounters ip on ap.suvida_id = ip.suvida_id