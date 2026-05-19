
  
    

create or replace transient table dw_dev.dev_jkizer.patient_clinical_program
    copy grants
    
    
    as (with date_boundaries as (
  select
    date_month_start,
    date_month_end,
    dateadd(month, -4, date_month_start) as four_months_before_start
  from (
    select distinct
      date_month as date_month_start,
      last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -18, current_date()) and current_date()
  )
),
subset_data as (
  select
    date_month_start,
    date_month_end,
    suvida_id,
    team,
    program,
    clinical_program_step,
    clinical_program_step_status
  from dw_dev.dev_jkizer.clinical_program_process_overview
),
pivot_data as (
  select
    p.date_month_start,
    p.date_month_end,
    p.suvida_id,
    p.team,
    p.program,
    $6 as is_eligible,
    $7 as is_referred,
    $8 as is_visit_enrollment,
    $9 as is_tag_enrollment
  from subset_data
  pivot (
    max(clinical_program_step_status)
    for clinical_program_step in ('eligible','referral','visit_enrollment','tag_enrollment')
  ) as p
),
uniq_referral as (
  select
    cpr.date_month_start,
    cpr.date_month_end,
    fr.referral_id,
    fr.suvida_id,
    cpr.referral_program,
    cpr.referral_team,
    fr.signed_date,
    cpr.resolution_state,
    cpr.referral_diagnoses,
    cpr.is_newly_referred
  from dw_dev.dev_jkizer.clinical_program_referral as cpr
  join date_boundaries db
    on cpr.date_month_start = db.date_month_start
    and cpr.date_month_end = db.date_month_end
  join dw_dev.dev_jkizer.fct_referral as fr
    on cpr.suvida_id = fr.suvida_id
    and fr.signed_date between db.four_months_before_start and db.date_month_end
  where fr.is_deleted = false
  qualify row_number() over (
    partition by fr.suvida_id, cpr.referral_team, cpr.referral_program, cpr.date_month_start 
    order by fr.signed_date asc, fr.creation_datetime asc
  ) = 1
),
uniq_first_visit as (
  select
    ur.date_month_start,
    ur.date_month_end,
    ur.suvida_id,
    ur.referral_team as team,
    ur.referral_program as program,
    fa.appointment_date as first_visit_date
  from uniq_referral as ur
  join dw_dev.dev_jkizer.fct_appointment as fa
    on fa.suvida_id = ur.suvida_id
    and fa.appointment_date between ur.signed_date and ur.date_month_end
    and fa.appointment_status not in ('cancelled','notSeen')
  qualify row_number() over (
    partition by ur.suvida_id, ur.referral_team, ur.referral_program, ur.date_month_start 
    order by fa.appointment_date asc, fa.creation_datetime asc
  ) = 1
)
select
  md5(cast(coalesce(cast(pdpl.date_month_start as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pdpl.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pdpl.team as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pdpl.program as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_clinical_program_skey,
  pdpl.date_month_start,
  pdpl.date_month_end,
  pdpl.suvida_id,
  pdpl.team,
  pdpl.program,
  pdpl.is_eligible,
  pdpl.is_referred,
  pdpl.is_visit_enrollment,
  pdpl.is_tag_enrollment,
  cpe.eligibility_logic,
  cpe.eligibility_evidence,
  cpe.is_newly_eligible,
  uqr.signed_date as referral_signed_date,
  uqr.resolution_state as referral_resolution_state,
  uqr.referral_diagnoses as referral_diagnoses,
  datediff(day, uqr.signed_date, ufv.first_visit_date) as days_from_referral_to_first_visit,
  uqr.is_newly_referred as is_newly_referred,
  cpe_visit.most_recent_provider,
  cpe_visit.most_recent_appointment, 
  cpe_visit.visits_in_last_4_months,
  cpe_visit.visits_in_last_12_months,
  cpe_tag.tag_value
from pivot_data pdpl
left join uniq_referral uqr
  on pdpl.suvida_id = uqr.suvida_id
  and pdpl.team = uqr.referral_team
  and pdpl.program = uqr.referral_program
  and pdpl.date_month_start = uqr.date_month_start
left join uniq_first_visit ufv
  on pdpl.suvida_id = ufv.suvida_id
  and pdpl.team = ufv.team
  and pdpl.date_month_start = ufv.date_month_start
  and pdpl.program = ufv.program
left join dw_dev.dev_jkizer.clinical_program_eligibility as cpe
  on pdpl.suvida_id = cpe.suvida_id
  and pdpl.team = cpe.team
  and pdpl.program = cpe.program
  and pdpl.date_month_start = cpe.date_month_start
left join dw_dev.dev_jkizer.clinical_program_enrollment as cpe_visit
  on pdpl.suvida_id = cpe_visit.suvida_id
  and pdpl.team = cpe_visit.enrollment_team
  and pdpl.date_month_start = cpe_visit.date_month_start
  and pdpl.program = cpe_visit.enrollment_program
  and cpe_visit.enrollment_type = 'visit'
left join dw_dev.dev_jkizer.clinical_program_enrollment as cpe_tag
  on pdpl.suvida_id = cpe_tag.suvida_id
  and pdpl.team = cpe_tag.enrollment_team
  and pdpl.program = cpe_tag.enrollment_program
  and pdpl.date_month_start = cpe_tag.date_month_start
  and cpe_tag.enrollment_type = 'tag'
    )
;


  