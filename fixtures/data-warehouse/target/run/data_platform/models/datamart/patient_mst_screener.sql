
  
    

create or replace transient table dw_dev.dev_jkizer.patient_mst_screener
    copy grants
    
    
    as (--
-- MST (Malnutrition Screening Tool) score per patient, computed from the most recent HRA
-- submission. Sourced from fct_form_response filtered to form_family = 'hra' so the model
-- automatically picks up new HRA form versions added in map_zentake_form_family.
--
-- Output grain: one row per patient (latest HRA only).
--

with hra_responses as (
    select
        suvida_id,
        response_id,
        sent_at_datetime,
        completed_at_datetime,
        question_concept,
        answer_text
    from dw_dev.dev_jkizer.fct_form_response
    where form_family = 'hra'
      and suvida_id  is not null
),

latest_response as (
    select
        suvida_id,
        response_id,
        sent_at_datetime,
        completed_at_datetime
    from hra_responses
    qualify row_number() over (
        partition by suvida_id
        order by sent_at_datetime desc, response_id desc
    ) = 1
),

mst_answers as (
    select
        lr.suvida_id,
        lr.completed_at_datetime,
        hr.question_concept,
        hr.answer_text
    from latest_response lr
    inner join hra_responses hr
        on hr.suvida_id   = lr.suvida_id
       and hr.response_id = lr.response_id
    where hr.question_concept in (
        'Have you recently lost weight without trying?',
        'If yes, how much weight have you lost?',
        'Have you been eating poorly because of a decreased appetite?'
    )
),

question_scores as (
    select
        suvida_id,
        completed_at_datetime,

        max(case
            when question_concept ilike 'Have you recently lost weight without trying?'
            then answer_text
        end) as unintentional_wt_loss_response,

        max(case
            when question_concept ilike 'Have you recently lost weight without trying?'
                 and answer_text in ('Yes','Sí (1)','Unsure','No estoy seguro (2)') then 2
            when question_concept ilike 'Have you recently lost weight without trying?' then 0
            else 0
        end) as unintentional_wt_loss_score,

        max(case
            when question_concept = 'If yes, how much weight have you lost?'
            then answer_text
        end) as weight_loss_range_response_raw,

        max(case
            when question_concept ilike 'If yes, how much weight have you lost?'
                 and answer_text ilike 'No estoy seguro (2)%' then 2
            when question_concept ilike 'If yes, how much weight have you lost?'
                 and answer_text ilike 'Unsure%'              then 2
            when question_concept ilike 'If yes, how much weight have you lost?'
                 and answer_text ilike '2-13%'                then 1
            when question_concept ilike 'If yes, how much weight have you lost?'
                 and answer_text ilike '14-23 lb%'            then 2
            when question_concept ilike 'If yes, how much weight have you lost?'
                 and answer_text ilike '24-33 lb%'            then 3
            when question_concept ilike 'If yes, how much weight have you lost?'
                 and answer_text ilike '34 lb%'               then 4
            else 0
        end) as weight_loss_range_score,

        max(case
            when question_concept ilike 'Have you been eating poorly because of a decreased appetite?'
            then answer_text
        end) as poor_appetite_response,

        max(case
            when question_concept ilike 'Have you been eating poorly because of a decreased appetite?'
                 and answer_text in ('Yes','Sí') then 1
            else 0
        end) as poor_appetite_score
    from mst_answers
    group by suvida_id, completed_at_datetime
)

select
    qs.suvida_id,
    qs.completed_at_datetime,

    qs.unintentional_wt_loss_response,
    qs.unintentional_wt_loss_score,

    coalesce(qs.weight_loss_range_response_raw, 'N/A') as weight_loss_range_response,
    qs.weight_loss_range_score,

    qs.poor_appetite_response,
    qs.poor_appetite_score,

    (qs.unintentional_wt_loss_score
     + qs.weight_loss_range_score
     + qs.poor_appetite_score) as mst_score,

    case
        when (qs.unintentional_wt_loss_score
              + qs.weight_loss_range_score
              + qs.poor_appetite_score) between 0 and 1 then 'Not At Risk'
        else 'At Risk'
    end as mst_risk_status
from question_scores qs
    )
;


  