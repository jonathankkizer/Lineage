--
-- BI-facing Zentake form response model. Thin enrichment layer over fct_form_response that
-- attaches Rippling staff context to each form response. Column names preserved (question,
-- answer, etc.) for Lightdash backward-compat; underlying grain is now one row per
-- (suvida_id, response_id, question_concept) — multi-select answer choices are listagg'd.
--

select
    md5(cast(coalesce(cast(ffr.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ffr.response_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ffr.question_concept as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as zentake_response_skey,
    ffr.suvida_id,
    ffr.form_id,
    ffr.form_name,
    ffr.form_family,
    ffr.form_version,
    ffr.language,
    ffr.regulatory_state,
    ffr.user_email,
    ffr.question_id,
    ffr.question_concept                                                            as question,
    ffr.answer_text                                                                 as answer,
    ffr.sent_at_datetime,
    ffr.completed_at_datetime,
    datediff(minute, ffr.sent_at_datetime, ffr.completed_at_datetime)               as minutes_to_complete_question,
    ffr.secure_status,
    coalesce(ffr.is_insecure, false)                                                as is_insecure,
    drs.full_name                                                                   as rippling_full_name,
    drs.department                                                                  as rippling_department,
    drs.title                                                                       as rippling_title,
    drs.work_location                                                               as rippling_work_location,
    drs.work_location_city                                                          as rippling_work_location_city,
    drs.work_location_state                                                         as rippling_work_location_state,
    drs.work_location_zip                                                           as rippling_work_location_zip,
    drs.location_description                                                        as rippling_location_description,
    drs.job_family_name                                                             as rippling_job_family_name
from dw_dev.dev_jkizer.fct_form_response ffr
left join dw_dev.dev_jkizer.dim_rippling_staff drs
    on ffr.user_email = drs.work_email