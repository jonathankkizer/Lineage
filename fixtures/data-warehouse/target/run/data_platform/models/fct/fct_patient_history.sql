
  
    

create or replace transient table dw_dev.dev_jkizer.fct_patient_history
    copy grants
    
    
    as (with
/* ============================
   mini-cog
   ============================ */
mini_cog as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      'Mini-Cog' as history_type,
      split(ph.history_value, ' ')[3]::string as history_value,
      try_to_decimal(split(ph.history_value, ' ')[3]::string) as history_value_numeric,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type = 'Cognitive'
    and ph.history_value like 'Cognitive: Mini-Cog Score:%'

  union all

  select
      cast(fcs.suvida_id as varchar) as suvida_id,
      cast(fcs.patient_id as varchar) as patient_id,
      fcs.history_form_name as history_type,
      fcs.answer as history_value,
      try_to_decimal(fcs.answer) as history_value_numeric,
      null as history_value_relationship_type,
      null as history_value_rank,
      fcs.creation_date_time as creation_datetime,
      fcs.creation_date_time as last_modified_datetime,
      fcs.created_by_user_id
  from dw_dev.dev_jkizer.fct_clinical_score fcs
  where fcs.history_form_name = 'Mini-Cog'
),

/* ============================
   gad-7
   ============================ */
gad7 as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      'GAD-7' as history_type,
      split(ph.history_value, ' ')[3]::string as history_value,
      try_to_decimal(split(ph.history_value, ' ')[3]::string) as history_value_numeric,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type = 'Psychological'
    and ph.history_value like 'Anxiety: GAD-7 Score:%'

  union all

  select
      cast(fcs.suvida_id as varchar),
      cast(fcs.patient_id as varchar),
      fcs.history_form_name,
      fcs.answer,
      try_to_decimal(fcs.answer),
      null, null,
      fcs.creation_date_time,
      fcs.creation_date_time,
      fcs.created_by_user_id
  from dw_dev.dev_jkizer.fct_clinical_score fcs
  where fcs.history_form_name = 'GAD-7'
),

/* ============================
   katz-adl
   ============================ */
katz_adl as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      'KATZ-ADL' as history_type,
      split(ph.history_value, ' ')[3]::string as history_value,
      try_to_decimal(split(ph.history_value, ' ')[3]::string) as history_value_numeric,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type like '%KATZ-ADL%'

  union all

  select
      cast(fcs.suvida_id as varchar),
      cast(fcs.patient_id as varchar),
      fcs.history_form_name,
      fcs.answer,
      try_to_decimal(fcs.answer),
      null, null,
      fcs.creation_date_time,
      fcs.creation_date_time,
      fcs.created_by_user_id
  from dw_dev.dev_jkizer.fct_clinical_score fcs
  where fcs.history_form_name = 'KATZ-ADL'
),

/* ============================
   phq-9
   ============================ */
phq9 as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      'PHQ-9' as history_type,
      split(ph.history_value, ' ')[3]::string as history_value,
      try_to_decimal(split(ph.history_value, ' ')[3]::string) as history_value_numeric,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type = 'Psychological'
    and ph.history_value like 'Depression: PHQ-9 Score:%'

  union all

  select
      cast(fcs.suvida_id as varchar),
      cast(fcs.patient_id as varchar),
      fcs.history_form_name,
      fcs.answer,
      try_to_decimal(fcs.answer),
      null, null,
      fcs.creation_date_time,
      fcs.creation_date_time,
      fcs.created_by_user_id
  from dw_dev.dev_jkizer.fct_clinical_score fcs
  where fcs.history_form_name = 'PHQ-9'
),

/* ============================
   phq-2
   ============================ */
phq2 as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      'PHQ-2' as history_type,
      split(ph.history_value, ' ')[3]::string as history_value,
      try_to_decimal(split(ph.history_value, ' ')[3]::string) as history_value_numeric,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type = 'Psychological'
    and ph.history_value like 'Depression: PHQ-2 Score:%'

  union all

  select
      cast(fcs.suvida_id as varchar),
      cast(fcs.patient_id as varchar),
      fcs.history_form_name,
      fcs.answer,
      try_to_decimal(fcs.answer),
      null, null,
      fcs.creation_date_time,
      fcs.creation_date_time,
      fcs.created_by_user_id
  from dw_dev.dev_jkizer.fct_clinical_score fcs
  where fcs.history_form_name = 'PHQ-2'
),

/* ============================
   audit-c
   ============================ */
auditc as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      'Alcohol use' as history_type,
      split(ph.history_value, ' ')[4]::string as history_value,
      try_to_decimal(split(ph.history_value, ' ')[4]::string) as history_value_numeric,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type = 'Habits'
    and ph.history_value like 'Alcohol use: AUDIT-C Score:%'

  union all

  select
      cast(fcs.suvida_id as varchar),
      cast(fcs.patient_id as varchar),
      fcs.history_form_name,
      fcs.answer,
      try_to_decimal(fcs.answer),
      null, null,
      fcs.creation_date_time,
      fcs.creation_date_time,
      fcs.created_by_user_id
  from dw_dev.dev_jkizer.fct_clinical_score fcs
  where fcs.history_form_name = 'Alcohol use'
),

/* ============================
   tug parsing
   ============================ */
tug_parsing_clean as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      ph.history_value as original_value,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id,
      case 
        when ph.history_type = 'Maintenance' and ph.history_value like '%TUG:%' then 'TUG'
        when ph.history_type = 'Functional'  and ph.history_value like '%Pre-%'  and ph.history_value like '%Timed Up and Go Test:%' then 'Pre-TUG'
        when ph.history_type = 'Functional'  and ph.history_value like '%Post-%' and ph.history_value like '%Timed Up and Go Test:%' then 'Post-TUG'
            end as tug_type,
      case 
        when ph.history_value like '%NT%patient%' 
          or ph.history_value like '%NT%Per%'
          or ph.history_value like '%NT%wheelchair%'
          or regexp_substr(ph.history_value, ':[^:]*$') like '%NT%' then 'NT'  -- extracts everything after the last colon
        when regexp_substr(ph.history_value, ':[^:]*$') like '%NA%' then 'NA'  -- extracts everything after the last colon
        else null
            end as special_value,
            
      case 
        when trim(regexp_substr(ph.history_value, ':[^:]*$')) = ''  -- extracts everything after the last colon
          or regexp_substr(ph.history_value, ':[^:]*$') rlike '^\\s*$'  -- checks if segment is empty or whitespace only
          or regexp_substr(ph.history_value, ':[^:]*$') like '% AM:%'
          or regexp_substr(ph.history_value, ':[^:]*$') like '% PM:%' 
        then regexp_substr(ph.history_value, ':[^:]*:[^:]*$')  -- gets segment after second-to-last colon (for timestamp cases)
        else regexp_substr(ph.history_value, ':[^:]*$')  -- gets segment after last colon
            end as segment_to_parse
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and (
         (ph.history_type = 'Maintenance' and ph.history_value like '%TUG:%')
      or (ph.history_type = 'Functional'  and ph.history_value like '%Timed Up and Go Test:%')
        )
),

tug_step2_extract as (
  select
      suvida_id,
      patient_id,
      tug_type,
      history_value_relationship_type,
      history_value_rank,
      creation_datetime,
      last_modified_datetime,
      created_by_user_id,
      case
        when special_value is not null then special_value
            else regexp_replace(
                regexp_substr(segment_to_parse, '\\d+\\.?\\d*["'']?'),  -- extracts numbers (with optional decimal and quote marks)
                    '[^0-9.]','')  -- strips all non-numeric characters except decimal point
                        end as history_value,
      case
        when special_value is not null then null
            else try_to_decimal(
                regexp_replace(
                    regexp_substr(segment_to_parse, '\\d+\\.?\\d*["'']?'),  -- extracts numbers (with optional decimal and quote marks)
                        '[^0-9.]',''),  -- strips all non-numeric characters except decimal point
                            10,2)
                                end as history_value_numeric
  from tug_parsing_clean
),

/* ============================
   chair-stand parsing
   ============================ */
chair_stand_parsing_clean as (
  select
      cast(siw.suvida_id as varchar) as suvida_id,
      cast(ph.patient_id as varchar) as patient_id,
      ph.history_value as original_value,
      ph.history_value_relationship_type,
      ph.history_value_rank,
      ph.creation_datetime,
      ph.last_modified_datetime,
      ph.created_by_user_id,
      case 
        when ph.history_type = 'Functional' and ph.history_value like '%Pre-%'  and ph.history_value like '%30 Second Chair Stand Test:%' then 'Pre-Chair-Stand'
        when ph.history_type = 'Functional' and ph.history_value like '%Post-%' and ph.history_value like '%30 Second Chair Stand Test:%' then 'Post-Chair-Stand'
            end as chair_stand_type,
      case 
        when ph.history_value like '%NT%patient%' 
          or ph.history_value like '%NT%scooter%'
          or ph.history_value like '%NT%wheelchair%'
          or regexp_substr(ph.history_value, ':[^:]*$') like '%NT%' then 'NT'  -- extracts everything after the last colon
        when regexp_substr(ph.history_value, ':[^:]*$') like '%NA%' then 'NA'  -- extracts everything after the last colon
        else null
            end as special_value,
            
      case 
        when trim(regexp_substr(ph.history_value, ':[^:]*$')) = ''  -- extracts everything after the last colon
          or regexp_substr(ph.history_value, ':[^:]*$') rlike '^\\s*$'  -- checks if segment is empty or whitespace only
          or regexp_substr(ph.history_value, ':[^:]*$') like '% AM:%'
          or regexp_substr(ph.history_value, ':[^:]*$') like '% PM:%' 
        then regexp_substr(ph.history_value, ':[^:]*:[^:]*$')  -- gets segment after second-to-last colon (for timestamp cases)
        else regexp_substr(ph.history_value, ':[^:]*$')  -- gets segment after last colon
            end as segment_to_parse
  from dw_dev.dev_jkizer_staging.stg_elation_patient_history ph
  left join dw_dev.dev_jkizer.suvida_id_walk siw
    on ph.patient_id = siw.member_id and ph.source = siw.source
  where ph.deletion_datetime is null
    and ph.history_type = 'Functional'
    and ph.history_value like '%30 Second Chair Stand Test:%'
),

chair_stand_extract as (
  select
      suvida_id,
      patient_id,
      chair_stand_type,
      history_value_relationship_type,
      history_value_rank,
      creation_datetime,
      last_modified_datetime,
      created_by_user_id,
      case
        when special_value is not null then special_value
            else regexp_replace(
                regexp_substr(segment_to_parse, '\\d+\\.?\\d*["'']?'),  -- extracts numbers (with optional decimal and quote marks)
                    '[^0-9.]','')  -- strips all non-numeric characters except decimal point
                        end as history_value,
      case
        when special_value is not null then null
            else try_to_decimal(
               regexp_replace(
                    regexp_substr(segment_to_parse, '\\d+\\.?\\d*["'']?'),  -- extracts numbers (with optional decimal and quote marks)
                        '[^0-9.]',''),  -- strips all non-numeric characters except decimal point
                            10,2)
                                end as history_value_numeric
  from chair_stand_parsing_clean
)

/* ============================
   final union
   ============================ */
select
  cast(tse.suvida_id as varchar) as suvida_id,
  cast(tse.patient_id as varchar) as patient_id,
  'TUG' as history_type,
  tse.history_value,
  tse.history_value_numeric,
  tse.history_value_relationship_type,
  tse.history_value_rank,
  tse.creation_datetime,
  tse.last_modified_datetime,
  tse.created_by_user_id,
  dense_rank() over (partition by tse.suvida_id order by tse.creation_datetime desc) as patient_history_index
from tug_step2_extract tse
where tse.tug_type = 'TUG'

union all
select
  cast(tse.suvida_id as varchar),
  cast(tse.patient_id as varchar),
  'Pre-TUG',
  tse.history_value,
  tse.history_value_numeric,
  tse.history_value_relationship_type,
  tse.history_value_rank,
  tse.creation_datetime,
  tse.last_modified_datetime,
  tse.created_by_user_id,
  dense_rank() over (partition by tse.suvida_id order by tse.creation_datetime desc)
from tug_step2_extract tse
where tse.tug_type = 'Pre-TUG'

union all
select
  cast(tse.suvida_id as varchar),
  cast(tse.patient_id as varchar),
  'Post-TUG',
  tse.history_value,
  tse.history_value_numeric,
  tse.history_value_relationship_type,
  tse.history_value_rank,
  tse.creation_datetime,
  tse.last_modified_datetime,
  tse.created_by_user_id,
  dense_rank() over (partition by tse.suvida_id order by tse.creation_datetime desc)
from tug_step2_extract tse
where tse.tug_type = 'Post-TUG'

union all
select
  cast(cse.suvida_id as varchar),
  cast(cse.patient_id as varchar),
  'Pre-Chair-Stand',
  cse.history_value,
  cse.history_value_numeric,
  cse.history_value_relationship_type,
  cse.history_value_rank,
  cse.creation_datetime,
  cse.last_modified_datetime,
  cse.created_by_user_id,
  dense_rank() over (partition by cse.suvida_id order by cse.creation_datetime desc)
from chair_stand_extract cse
where cse.chair_stand_type = 'Pre-Chair-Stand'

union all
select
  cast(cse.suvida_id as varchar),
  cast(cse.patient_id as varchar),
  'Post-Chair-Stand',
  cse.history_value,
  cse.history_value_numeric,
  cse.history_value_relationship_type,
  cse.history_value_rank,
  cse.creation_datetime,
  cse.last_modified_datetime,
  cse.created_by_user_id,
  dense_rank() over (partition by cse.suvida_id order by cse.creation_datetime desc)
from chair_stand_extract cse
where cse.chair_stand_type = 'Post-Chair-Stand'

union all
select
  cast(mc.suvida_id as varchar),
  cast(mc.patient_id as varchar),
  mc.history_type,
  mc.history_value,
  mc.history_value_numeric,
  mc.history_value_relationship_type,
  mc.history_value_rank,
  mc.creation_datetime,
  mc.last_modified_datetime,
  mc.created_by_user_id,
  row_number() over (partition by mc.suvida_id order by mc.creation_datetime desc)
from mini_cog mc

    union all
    
select
  cast(g7.suvida_id as varchar),
  cast(g7.patient_id as varchar),
  g7.history_type,
  g7.history_value,
  g7.history_value_numeric,
  g7.history_value_relationship_type,
  g7.history_value_rank,
  g7.creation_datetime,
  g7.last_modified_datetime,
  g7.created_by_user_id,
  dense_rank() over (partition by g7.suvida_id order by g7.creation_datetime desc)
from gad7 g7

    union all

select
  cast(p9.suvida_id as varchar),
  cast(p9.patient_id as varchar),
  p9.history_type,
  p9.history_value,
  p9.history_value_numeric,
  p9.history_value_relationship_type,
  p9.history_value_rank,
  p9.creation_datetime,
  p9.last_modified_datetime,
  p9.created_by_user_id,
  dense_rank() over (partition by p9.suvida_id order by p9.creation_datetime desc)
from phq9 p9

    union all

select
  cast(p2.suvida_id as varchar),
  cast(p2.patient_id as varchar),
  p2.history_type,
  p2.history_value,
  p2.history_value_numeric,
  p2.history_value_relationship_type,
  p2.history_value_rank,
  p2.creation_datetime,
  p2.last_modified_datetime,
  p2.created_by_user_id,
  dense_rank() over (partition by p2.suvida_id order by p2.creation_datetime desc)
from phq2 p2

    union all

select
  cast(ac.suvida_id as varchar),
  cast(ac.patient_id as varchar),
  ac.history_type,
  ac.history_value,
  ac.history_value_numeric,
  ac.history_value_relationship_type,
  ac.history_value_rank,
  ac.creation_datetime,
  ac.last_modified_datetime,
  ac.created_by_user_id,
  dense_rank() over (partition by ac.suvida_id order by ac.creation_datetime desc)
FROM auditc ac

    union all

select
  cast(kz.suvida_id as varchar),
  cast(kz.patient_id as varchar),
  kz.history_type,
  kz.history_value,
  kz.history_value_numeric,
  kz.history_value_relationship_type,
  kz.history_value_rank,
  kz.creation_datetime,
  kz.last_modified_datetime,
  kz.created_by_user_id,
  dense_rank() over (partition by kz.suvida_id order by kz.creation_datetime desc)
FROM katz_adl kz
    )
;


  