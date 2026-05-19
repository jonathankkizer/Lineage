with coder_attestation_opportunities as (
    select
        attestation_opportunity_skey,
        created_datetime,
        row_number() over (partition by attestation_opportunity_skey order by created_datetime) as _idx
    from dw_dev.dev_jkizer.fct_coder_attestation_diagnosis
), text_cleanup as (
    select
        *,
        /* Below are EXAMPLES and would need polish */
        icd_10_code || ' - ' || code_description as gap_title,
        array_to_string(array_construct_compact(coder_info, redoc_info, payer_suspect_info), ' | ') as gap_short_text, -- order: redoc, coder, payer suspect
        array_to_string(array_construct_compact(mapped_hccs), ' | ') as long_text,
    from dw_dev.dev_jkizer.attestation_opportunity
    where measure_year = year(current_date())
), uat_filter_criteria as (
    select suvida_id, elation_id, num_pcp_visits_ytd
    from dw_dev.dev_jkizer.int_patient_summary_sandbox ps
), version_skey as (
    select
        tc.*,
        ufc.elation_id,
        md5(cast(coalesce(cast(attestation_opportunity_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(gap_title as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(gap_short_text as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(long_text as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as attestation_opportunity_version_skey,
    from text_cleanup tc
    inner join uat_filter_criteria ufc
        on md5(cast(coalesce(cast(tc.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) = ufc.suvida_id
), int_attestation_opportunity as (
    select
        vs.*,
        ael.caregap_id,
        case
            when ael.attestation_opportunity_skey is not null and ael.action != 'Close' and vs.attestation_opportunity_status = 'closed' then 'close'
            when ael.attestation_opportunity_skey is null and vs.attestation_opportunity_status = 'open' then 'create'
            when ael.attestation_opportunity_skey is not null and vs.attestation_opportunity_status = 'open' and ael.action = 'Close' then 'create'
            when vs.attestation_opportunity_version_skey != ael.attestation_opportunity_version_skey and ael.action != 'Close' then 'update'
            else null
        end as attestation_event_needed_action,
    from version_skey vs
    left join dw_dev.dev_jkizer_staging.stg_attestation_event_log ael
        on vs.attestation_opportunity_skey = ael.attestation_opportunity_skey
        and ael.attestation_process_event_index = 1
), hccs as (
    select
        attestation_opportunity_version_skey,
        array_to_string(
        array_agg(
            trim(
                replace(value::string, 'Relevant HCC(s): ', '')
            )
        ),
        '||'
    ) as hcc_list
    from int_attestation_opportunity t,
        lateral flatten(
            input => split(t.mapped_hccs, ' | ')
        )
    group by all
)

select distinct    
    iao.attestation_opportunity_skey,
    iao.attestation_opportunity_version_skey,
    ipsu.suvida_id,
    ipsu.elation_id,
    iao.measure_year,
    iao.icd_10_code,
    iao.problem_id,
    iao.problem_list_icd_10_code,
    iao.icd_10_code_description,
    iao.problem_list_description,
    iao.code_description,
    iao.attestation_opportunity_status,
    iao.is_emr_diagnosis_complete,
    iao.elation_action_type,
    iao.is_emr_action_complete,
    iao.is_attestation_opportunity_created,
    iao.is_payer_opportunity,
    iao.is_redoc_opportunity,
    iao.is_coder_opportunity,
    null as coder_evidence,
    iao.mapped_hccs,
    iao.max_payer_report_date,
    case
        when is_redoc_opportunity then to_number(measure_year, 18, 0) || '-01-01'
        when is_payer_opportunity then max_payer_report_date
        when is_coder_opportunity then cao.created_datetime
        else null
    end as created_datetime,
    null as payer_suspect_info,
    null as redoc_info,
    null as coder_info,
    iao.most_recent_emr_diagnosis_date,
    iao.source,
    iao.gap_title,
    null as gap_short_text,
    null as long_text,
    null as caregap_id,
    iao.attestation_event_needed_action,
    hccs.hcc_list,
    u.user_id as actioned_by_user_id,
    u.user_email as actioned_by_user_email,
    u.user_name as actioned_by_user_name,
    ecg.date as actioned_date,
    ecg.document_id as actioning_visit_note_id,
    ecg.reminder_action as action_taken
from int_attestation_opportunity iao
left join hccs
    on iao.attestation_opportunity_version_skey = hccs.attestation_opportunity_version_skey
left join dw_dev.dev_jkizer.int_patient_summary_sandbox ipsu
    on md5(cast(coalesce(cast(iao.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) = ipsu.suvida_id
left join coder_attestation_opportunities cao
    on iao.attestation_opportunity_skey = cao.attestation_opportunity_skey and
       cao._idx = 1
left join dw_dev.dev_jkizer_staging.stg_elation_caregap_engagement ecg
    on iao.caregap_id = ecg.gap_id
left join dw_dev.dev_jkizer.ehr_user u
    on lower(trim(ecg.user)) = lower(trim(u.user_email))
where
    ipsu.suvida_id is not null
qualify row_number() over (partition by ipsu.suvida_id, iao.attestation_opportunity_skey, iao.attestation_opportunity_version_skey order by ecg.date desc) = 1