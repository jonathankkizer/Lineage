

with date_spine as (
  select
    date_trunc('month', date_month) as spine_month
  from dw_dev.dev_jkizer.dim_date
  where is_bom = 1
    and date_day <= current_date
    and date_month >= '2023-01-01' 
    
      and datediff(month, date_day, current_date) <= 4
    
),
proc_flags as (
  select
    encounter_skey,
    max(is_pcp) as is_pcp
  from dw_dev.dev_jkizer.fct_procedure
  group by encounter_skey
),
filtered_encounters as (
  select
    fct.suvida_id,
    fct.physician_user_id,
    dp.npi,
    fct.encounter_date as activity_date,
    'encounter' as activity_type
  from dw_dev.dev_jkizer.fct_encounter fct
  inner join proc_flags pf 
    on fct.encounter_skey = pf.encounter_skey
  inner join dw_dev.dev_jkizer.dim_provider dp 
    on fct.physician_user_id = dp.user_id
  where fct.encounter_type = 'clinical_encounter' 
    and fct.visit_note_name = 'Provider Note' 
    and pf.is_pcp = 1
    and fct.encounter_date >= (
      select dateadd(month, -24, min(spine_month)) from date_spine
    )
),
filtered_appointments as (
  select 
    fct.suvida_id,
    fct.user_id as physician_user_id,
    dp.npi,
    fct.appointment_date as activity_date,
    'appointment' as activity_type
  from dw_dev.dev_jkizer.fct_appointment fct
  inner join dw_dev.dev_jkizer.dim_provider dp 
    on fct.user_id = dp.user_id
  where fct.is_pcp_appt = true
    and fct.appointment_provider_category = 'PCP'
    and fct.appointment_date >= (
      select dateadd(month, -24, min(spine_month)) from date_spine
    )
),
all_activities as (
  select 
    suvida_id,
    npi,
    activity_date,
    activity_type
  from filtered_encounters

  union all

  select 
    suvida_id,
    npi,
    activity_date,
    activity_type
  from filtered_appointments
),
weighted_activity as (
  select
    ds.spine_month,
    a.suvida_id,
    a.npi,
    a.activity_date,
    a.activity_type,
    case 
      -- last 3 months (e.g. feb–apr if spine_month is may)
      when a.activity_date between dateadd(month, -3, ds.spine_month) and ds.spine_month and a.activity_type = 'encounter' then 3
      -- 4 to 12 months ago (e.g. may–jan if spine_month is may)
      when a.activity_date between dateadd(month, -12, ds.spine_month) and dateadd(day, -1, dateadd(month, -3, ds.spine_month)) and a.activity_type = 'encounter' then 2
      -- future appointments only (within 3 months ahead)
      when a.activity_date >= ds.spine_month 
        and a.activity_date < dateadd(month, 4, ds.spine_month)
        and a.activity_type = 'appointment' then 2
      -- older than 12 months
      when a.activity_date < dateadd(month, -12, ds.spine_month) and a.activity_type = 'encounter' then 1
      else 0
    end as activity_weight
  from date_spine ds
  join all_activities a 
    on a.activity_date between dateadd(month, -18, ds.spine_month) and dateadd(month, 3, ds.spine_month)
),
activity_aggregation as (
  select 
    spine_month,
    suvida_id,
    npi,
    sum(activity_weight) as weighted_activity_score,
    sum(case when activity_type = 'appointment' then 1 else 0 end) as appointment_total_activities,
    sum(case when activity_type = 'encounter' then 1 else 0 end) as encounter_total_activities,
    count(*) as total_activities
  from weighted_activity
  group by spine_month, suvida_id, npi
),
ranked_physicians as (
  select 
    spine_month,
    suvida_id,
    npi,
    weighted_activity_score,
    appointment_total_activities,
    encounter_total_activities,
    total_activities,
    row_number() over (partition by spine_month, suvida_id order by weighted_activity_score desc, encounter_total_activities desc) as provider_preference_rank
  from activity_aggregation
)
select
  spine_month as report_month,
  suvida_id,
  npi as assigned_npi,
  weighted_activity_score,
  appointment_total_activities,
  encounter_total_activities,
  total_activities,
  provider_preference_rank,
  case
    when provider_preference_rank = 1 then true
    else false
  end as current_provider_assignment
from ranked_physicians