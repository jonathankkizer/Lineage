with guia as (
    select
        md5(cast(coalesce(cast(t.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.task_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.task_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as row_skey,
        t.suvida_id,
        ips.elation_id,
        t.airtable_id,
        t.task_date,
        t.master_due_date as task_due_date,
        t.task_type,
        t.workflow_table as task_category,
        t.master_status,
        t.master_stage,
        t.workflow_stage,
        t.workflow_status,
        coalesce(iff(lower(t.urgency) like '%urgent%', TRUE, FALSE), false) as is_urgent,
        coalesce(t.is_overdue, false) as is_overdue,
        t.master_compas_note as note,
        'Guia' as task_team,
        t.active_owner as task_owner
    from dw_dev.dev_jkizer.patient_guia_task t
    inner join dw_dev.dev_jkizer.int_patient_summary ips
        on t.suvida_id = ips.suvida_id
),

mental_health_base as (
    select
        s.suvida_id,
        ips.elation_id,
        s.airtable_id,
        coalesce(s.referral_date, s.tag_creation_datetime::date) as task_date,
        null::date as task_due_date,
        s.care_programs_needed as task_type,
        'Mental Health' as task_category,
        s.referral_status as master_status,
        s.referral_stage as master_stage,
        s.scheduling_stage as workflow_stage,
        s.resolution_state as workflow_status,
        false as is_urgent,
        false as is_overdue,
        s.compas_note as note,
        'Mental Health' as task_team,
        s.assigned_mh_provider_name as task_owner
    from dw_dev.dev_jkizer.patient_shared_services_mh_referral s
    inner join dw_dev.dev_jkizer.int_patient_summary ips
        on s.suvida_id = ips.suvida_id
),

mental_health as (
    select
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as row_skey,
        suvida_id,
        elation_id,
        airtable_id,
        task_date,
        task_due_date,
        task_type,
        task_category,
        master_status,
        master_stage,
        workflow_stage,
        workflow_status,
        is_urgent,
        is_overdue,
        note,
        task_team,
        task_owner
    from mental_health_base
),

nutrition_base as (
    select
        s.suvida_id,
        ips.elation_id,
        s.airtable_id,
        coalesce(s.referral_date, s.tag_creation_datetime::date) as task_date,
        null::date as task_due_date,
        s.care_programs_needed as task_type,
        'Nutrition' as task_category,
        s.referral_status as master_status,
        s.referral_stage as master_stage,
        s.scheduling_stage as workflow_stage,
        s.resolution_state as workflow_status,
        false as is_urgent,
        false as is_overdue,
        s.compas_note as note,
        'Nutrition' as task_team,
        s.assigned_rd_name as task_owner
    from dw_dev.dev_jkizer.patient_shared_services_nutrition_referral s
    inner join dw_dev.dev_jkizer.int_patient_summary ips
        on s.suvida_id = ips.suvida_id
),

nutrition as (
    select
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as row_skey,
        suvida_id,
        elation_id,
        airtable_id,
        task_date,
        task_due_date,
        task_type,
        task_category,
        master_status,
        master_stage,
        workflow_stage,
        workflow_status,
        is_urgent,
        is_overdue,
        note,
        task_team,
        task_owner
    from nutrition_base
),

physical_therapy_base as (
    select
        s.suvida_id,
        ips.elation_id,
        s.airtable_id,
        coalesce(s.referral_date, s.tag_creation_datetime::date) as task_date,
        null::date as task_due_date,
        coalesce(s.care_programs_needed, s.cc_labeling_referral_type, s.tag_value) as task_type,
        'Physical Therapy' as task_category,
        s.referral_status as master_status,
        s.referral_stage as master_stage,
        s.scheduling_stage as workflow_stage,
        s.resolution_state as workflow_status,
        false as is_urgent,
        false as is_overdue,
        s.compas_note as note,
        'Physical Therapy' as task_team,
        s.assigned_pt_name as task_owner
    from dw_dev.dev_jkizer.patient_shared_services_pt_referral s
    inner join dw_dev.dev_jkizer.int_patient_summary ips
        on s.suvida_id = ips.suvida_id
),

physical_therapy as (
    select
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as row_skey,
        suvida_id,
        elation_id,
        airtable_id,
        task_date,
        task_due_date,
        task_type,
        task_category,
        master_status,
        master_stage,
        workflow_stage,
        workflow_status,
        is_urgent,
        is_overdue,
        note,
        task_team,
        task_owner
    from physical_therapy_base
),

pharmd_base as (
    select
        s.suvida_id,
        ips.elation_id,
        s.airtable_id,
        s.referred_date as task_date,
        null::date as task_due_date,
        s.pharmd_programs as task_type,
        'PharmD' as task_category,
        s.compas_status as master_status,
        s.enrollment_status as master_stage,
        s.scheduling_status as workflow_stage,
        null::string as workflow_status,
        false as is_urgent,
        false as is_overdue,
        s.compas_note as note,
        'PharmD' as task_team,
        s.pharmd_assignee_name as task_owner
    from dw_dev.dev_jkizer.patient_shared_services_pharmd_referral s
    inner join dw_dev.dev_jkizer.int_patient_summary ips
        on s.suvida_id = ips.suvida_id
),

pharmd as (
    select
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(task_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as row_skey,
        suvida_id,
        elation_id,
        airtable_id,
        task_date,
        task_due_date,
        task_type,
        task_category,
        master_status,
        master_stage,
        workflow_stage,
        workflow_status,
        is_urgent,
        is_overdue,
        note,
        task_team,
        task_owner
    from pharmd_base
),

unioned as (
    select * from guia
    union all
    select * from mental_health
    union all
    select * from nutrition
    union all
    select * from physical_therapy
    union all
    select * from pharmd
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by row_skey
            order by task_date desc nulls last, task_due_date desc nulls last, task_owner nulls last
        ) as row_skey_rank
    from unioned
)

select
    row_skey,
    suvida_id,
    elation_id,
    airtable_id,
    task_date,
    task_due_date,
    task_type,
    task_category,
    master_status,
    master_stage,
    workflow_stage,
    workflow_status,
    is_urgent,
    is_overdue,
    note,
    task_team,
    task_owner
from deduplicated
where row_skey_rank = 1