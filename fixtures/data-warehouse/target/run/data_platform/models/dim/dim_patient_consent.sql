
  
    

create or replace transient table dw_dev.dev_jkizer.dim_patient_consent
    copy grants
    
    
    as (--
-- Description: Current consent state per patient per consent category.
--
-- Grain: One row per (suvida_id, category). The most recent fct_consent event wins.
--
-- Purpose: downstream consumers (messaging integration, patient_summary) currently re-derive
--          "current state" via row_number() over (... order by completed_at_datetime desc).
--          This dim centralizes that logic so consumers join once and read latest_is_consented.
--

select
    md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(category as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_consent_skey,
    suvida_id,
    elation_id,
    category,
    is_consented           as latest_is_consented,
    is_implicit            as latest_is_implicit,
    completed_at_datetime  as latest_consent_at,
    source_key             as latest_response_id,
    form_name              as latest_form_name,
    form_version           as latest_form_version,
    language               as latest_language,
    regulatory_state       as latest_regulatory_state
from dw_dev.dev_jkizer.fct_consent
where suvida_id is not null
qualify row_number() over (partition by suvida_id, category order by completed_at_datetime desc) = 1
    )
;


  