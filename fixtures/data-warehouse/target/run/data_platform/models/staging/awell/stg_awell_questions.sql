
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_questions
  
  copy grants
  
  
  as (
    select 
    id as question_id,
    definition_id,
    form_definition_id,
    release_id,
    key,
    title,
    metadata,
    question_type,
    date(last_synced_at) as last_synced_at
from source_prod.awell.questions
  );

