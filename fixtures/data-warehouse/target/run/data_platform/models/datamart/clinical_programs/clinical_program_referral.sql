
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_program_referral
    copy grants
    
    
    as (with time_period as (
  select date_month as date_month_start, last_day(date_month) as date_month_end
  from dw_dev.dev_jkizer.dim_date
  where is_bom = true
    and date_day between dateadd(month, -12, current_date()) and current_date()
),

referrals_base as (
  select
      r.referral_id,
      r.suvida_id,
      lower(trim(r.recipient_org_name))              as recipient_org_name_norm,
      upper(r.referral_icd_list)                     as icd,
      lower(r.referral_icd_description_list)         as icd_desc,
      r.referral_body_text,                          -- needed for checkboxes
      r.clinical_reason,
      r.creation_date, r.signed_date, r.document_date,
      r.processing_status, r.resolution_state,
      coalesce(r.signed_date, r.document_date, r.creation_date) as effective_date
  from dw_dev.dev_jkizer.fct_referral r
  where lower(trim(r.recipient_org_name)) in (
      'mental health-therapy/counseling (suvida)',
      'nutrition (suvida)',
      'pharmacy (suvida)',
      'physical therapy (suvida)'
  )
    and r.suvida_id is not null
    and r.is_deleted = false
),

referrals_in_scope as (
  select
      rb.referral_id,
      rb.suvida_id,
      rb.recipient_org_name_norm,
      rb.icd,
      rb.icd_desc,
      rb.referral_body_text,
      rb.clinical_reason,
      rb.creation_date, rb.signed_date, rb.document_date,
      rb.processing_status, rb.resolution_state,
      tp.date_month_start, tp.date_month_end
  from referrals_base rb
  join time_period tp
    on rb.effective_date between dateadd(month, -4, tp.date_month_start) and tp.date_month_end
),

normalized_bodies as (
  select
    s.*,
    regexp_replace(
      regexp_replace(
        regexp_replace(s.referral_body_text,
          '<br\\s*/?>|</p>|</div>', '\n', 1, 0, 'i'),
        '\\r\\n|\\r|\\n', '\n'),
      '[\\x{2028}\\x{2029}]', '\n') as body_norm
  from referrals_in_scope s
  where s.recipient_org_name_norm in ('nutrition (suvida)', 'physical therapy (suvida)')
    -- Only process text for programs that check note body (food_rx, subienestar, matter_of_balance)
),

base_lines as (
  select
      nb.referral_id,
      nb.recipient_org_name_norm,
      t.index as line_no,
      trim(t.value::string) as line
  from normalized_bodies nb,
       lateral flatten(input => split(nb.body_norm, '\n')) t
),

checked_lines as (
  -- keep only lines explicitly checked: [x] or [X] (optionally allow [xx])
  select
      bl.referral_id,
      bl.recipient_org_name_norm,
      bl.line_no,
      bl.line,
      trim(substring(bl.line, charindex(']', bl.line) + 1)) as label
  from base_lines bl
  where regexp_like(bl.line, '^\\s*\\[(x|xx)\\]\\s*', 'i')
),
-- Map checked note lines to program tags (no subqueries later)
note_programs as (
  -- Food as Medicine / Food RX
  select distinct referral_id, 'food_rx' as program_code
  from checked_lines
  where regexp_like(label, '(food\\s*as\\s*medicine|food\\s*rx|food_rx|\\bfam\\b)', 'i')
),

quality_measures_in_scope as (
  select
    fqm.suvida_id,
    fqm.quality_measure,
    date_trunc('month', fqm.report_date) as report_month
  from dw_dev.dev_jkizer.fct_quality_measure fqm
  where fqm.quality_measure in (
    'Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults',
    'Statin Therapy for Cardiovascular Disease',
    'Statin Use in Persons with Diabetes'
  )
    and fqm.report_date >= (select dateadd(month, -13, min(date_month_start)) from time_period)
    and fqm.report_date <= (select max(date_month_end) from time_period)
),

/* ---------------- MH ---------------- */
mh_referrals as (
  -- MH-P (psychotic/bipolar/MDD/anxiety/OCD)
  select
      date_month_start,
      date_month_end,
      referral_id,
      'mh'   as referral_team,
      'mh_p' as referral_program,
      recipient_org_name_norm,
      listagg(distinct icd_desc, ' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'mental health-therapy/counseling (suvida)'
    and (
      icd ilike 'F42%'
      or icd ilike 'F20%' 
      or icd ilike 'F25%'
      or icd ilike 'F31%' 
      or icd ilike 'F33%'      
    )
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm

  union all

  -- MH-T (therapy; MDD/anxiety/OCD/PTSD via code or description)
  select
      date_month_start,
      date_month_end,
      referral_id,
      'mh'   as referral_team,
      'mh_t_individual' as referral_program,
      recipient_org_name_norm,
      listagg(distinct icd_desc, ' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'mental health-therapy/counseling (suvida)'
    and (
      icd ilike 'F32%' or icd ilike 'F33%' or icd ilike 'F41%' or icd ilike 'F43.1%'
      or icd_desc like '%recurrent depressive%' or icd_desc like '%generalized anxiety%' or icd_desc like '%panic disorder%'
      or icd_desc like '%ocd%' or icd_desc like '%ptsd%' or icd_desc like '%post traumatic stress%' or icd_desc like '%post-traumatic stress%'
      or icd_desc like '%depressive episode%'
    )
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm

  union all

  -- MH group (Adjustment)
  select
      date_month_start,
      date_month_end,
      referral_id,
      'mh'   as referral_team,
      'mh_t_group' as referral_program,
      recipient_org_name_norm,
      listagg(distinct icd_desc, ' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'mental health-therapy/counseling (suvida)'
    and (
      icd ilike 'F4321%' or icd_desc like '%adjustment disorder%'
    )
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm
),

/* ---------------- RD ---------------- */
rd_referrals as (
  
  -- Diabetes
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'rd' as referral_team, 
    'diabetes' as referral_program,
    recipient_org_name_norm,
    listagg(distinct icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'nutrition (suvida)'
    and (icd ilike 'E10%' or icd ilike 'E11%' or icd ilike 'E12%' or icd ilike 'E13%' or icd ilike 'E14%' or icd_desc like '%diabetes%' or icd_desc like '%dm%')
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm

  union all
  
  -- Food Rx (food insecurity)
  select 
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'rd' as referral_team,
    'food_rx' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct 'food_rx') as referral_diagnoses
  from referrals_in_scope r
  join dw_dev.dev_jkizer.fct_appointment fa 
    on r.suvida_id = fa.suvida_id
    and fa.appointment_date between r.date_month_start and r.date_month_end
  where r.recipient_org_name_norm = 'nutrition (suvida)'
  and fa.appointment_type_category = 'Food RX'
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm


  union all
  
  -- Subienestar (program tag only)
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'rd' as referral_team,
    'subienestar' as referral_program,
    recipient_org_name_norm,
    listagg(distinct'subienestar',' | ') as referral_diagnoses
  from referrals_in_scope r
  join dw_dev.dev_jkizer.fct_appointment fa 
    on r.suvida_id = fa.suvida_id
    and fa.appointment_date between r.date_month_start and r.date_month_end
  where r.recipient_org_name_norm = 'nutrition (suvida)'
  and fa.appointment_type_category like 'SuBienestar Class%'
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm

  union all
  
  -- Hypertension
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'rd' as referral_team,
    'hypertension' as referral_program,
    recipient_org_name_norm,
    listagg(distinct icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'nutrition (suvida)'
    and (icd ilike 'I10%' or icd ilike 'I11%' or icd ilike 'I12%' or icd ilike 'I13%' or icd ilike 'I15%' or icd_desc like '%hypertension%' or icd_desc like '%htn%')
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm

  union all
  
  -- Hyperlipidemia
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'rd' as referral_team,
    'hyperlipidemia' as referral_program,
    recipient_org_name_norm,
    listagg(distinct icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'nutrition (suvida)'
    and (icd ilike 'E78%' or icd_desc like '%hyperlipidemia%')
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm

  union all
  
  -- Malnutrition
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'rd' as referral_team,
    'malnutrition' as referral_program,
    recipient_org_name_norm,
    listagg(distinct icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'nutrition (suvida)'
    and (icd ilike 'E43%' or icd ilike 'E440%' or icd ilike 'R634%' or icd_desc like '%malnutrition%' or icd_desc like '%mnt%')
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm
),

/* ---------------- PharmD ---------------- */
pharmd_referrals as (
 
 -- Diabetes
  select 
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'pharmd' as referral_team,
    'diabetes' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct r.icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  where r.recipient_org_name_norm = 'pharmacy (suvida)'
    and (r.icd ilike 'E11.9%' or r.icd ilike 'E119%' or r.icd_desc like '%diabetes%' or r.icd_desc like '%dm%')
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm

  union all
  
  -- Hypertension
  select 
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'pharmd' as referral_team,
    'hypertension' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct r.icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  where r.recipient_org_name_norm = 'pharmacy (suvida)'
    and (r.icd ilike 'I10%' or r.icd_desc like '%hypertension%' or r.icd_desc like '%htn%')
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm

  union all
  
  -- CHF
  select 
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'pharmd' as referral_team,
    'chf' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct r.icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  where r.recipient_org_name_norm = 'pharmacy (suvida)'
    and (r.icd ilike 'I50.9%' or r.icd ilike 'I509%' or r.icd_desc like '%congestive heart%' or r.icd_desc like '%chf%')
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm

  union all
  
  -- Polypharmacy (description-led)
  select
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'pharmd' as referral_team,
    'polypharm' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct r.icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  left join quality_measures_in_scope qm
    on r.suvida_id = qm.suvida_id
    and qm.report_month between dateadd(month, -1, r.date_month_start) and r.date_month_end
    and qm.quality_measure = 'Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults'
  where r.recipient_org_name_norm = 'pharmacy (suvida)'
    and (r.icd_desc like '%polypharm%' or r.icd_desc like '%polypharmacy%')
    and qm.quality_measure is not null
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm

  union all
  
  -- Statin
  select
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'pharmd' as referral_team,
    'statin_cvd' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct r.icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  left join quality_measures_in_scope qm
    on r.suvida_id = qm.suvida_id
    and qm.report_month between dateadd(month, -1, r.date_month_start) and r.date_month_end
    and qm.quality_measure = 'Statin Therapy for Cardiovascular Disease'
  where r.recipient_org_name_norm = 'pharmacy (suvida)'
    and (
      (r.icd ilike 'E10%' or r.icd ilike 'E11%' or r.icd ilike 'E12%' or r.icd ilike 'E13%' or r.icd ilike 'E14%')
      and (r.icd_desc like '%statin%')
      or qm.quality_measure is not null
    )
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm

  union all
  
  -- SUPD
  select
    r.date_month_start,
    r.date_month_end,
    r.referral_id,
    'pharmd' as referral_team,
    'supd' as referral_program,
    r.recipient_org_name_norm,
    listagg(distinct r.icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  left join quality_measures_in_scope qm
    on r.suvida_id = qm.suvida_id
    and qm.report_month between dateadd(month, -1, r.date_month_start) and r.date_month_end
    and qm.quality_measure = 'Statin Use in Persons with Diabetes'
  where r.recipient_org_name_norm = 'pharmacy (suvida)'
    and (
      (r.icd ilike 'E10%' or r.icd ilike 'E11%' or r.icd ilike 'E12%' or r.icd ilike 'E13%' or r.icd ilike 'E14%')
      and (r.icd_desc like '%statin%' or r.icd_desc like '%supd%')
      or qm.quality_measure is not null
    )
  group by r.date_month_start, r.date_month_end, r.referral_id, r.recipient_org_name_norm
),

/* ---------------- PT ---------------- */
pt_referrals as (

  -- Matter of Balance (falls) — code or program text
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'pt' as referral_team,
    'matter_of_balance' as referral_program,
    recipient_org_name_norm,
    listagg(distinct icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope r
  where r.recipient_org_name_norm = 'physical therapy (suvida)'
  and clinical_reason like '%Matter of Balance" class%'
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm

  union all
  
  -- Post-stroke / TIA
  select 
    date_month_start,
    date_month_end,
    referral_id,
    'pt' as referral_team,
    'post_stroke' as referral_program,
    recipient_org_name_norm,
    listagg(distinct icd_desc,' | ') as referral_diagnoses
  from referrals_in_scope
  where recipient_org_name_norm = 'physical therapy (suvida)'
    and (
      icd ilike 'I60%' or icd ilike 'I61%' or icd ilike 'I62%' or icd ilike 'I63%' or icd ilike 'I64%' or
      icd ilike 'G45%' or icd_desc like 'G81%' or icd_desc like '%post stroke%' or icd_desc like '%post-stroke%'
    )
  group by date_month_start, date_month_end, referral_id, recipient_org_name_norm
),

referrals_all as (
  select * from mh_referrals
    union all 
  select * from rd_referrals
    union all 
  select * from pt_referrals
    union all 
  select * from pharmd_referrals
),

final_rows as (
  select
    ra.date_month_start,
    ra.date_month_end,
    ra.referral_id,
    ra.referral_team,
    ra.referral_program,
    ra.recipient_org_name_norm as recipient_org_name,
    ra.referral_diagnoses,
    pr.suvida_id,
    pr.referral_body_text,
    pr.creation_date,
    pr.signed_date,
    pr.document_date as referral_date,
    pr.processing_status,
    pr.resolution_state
  from referrals_all ra
  join referrals_in_scope pr
    on pr.referral_id = ra.referral_id
    and pr.date_month_start = ra.date_month_start
    and pr.date_month_end = ra.date_month_end
),
-- NEW: collapse to 1 row per patient×month×team×program
deduped as (
  select 
    *
  from final_rows
  qualify row_number() over (partition by suvida_id, date_month_start, date_month_end, referral_team, referral_program    -- 1 row per patient per program per month 
      order by coalesce(signed_date, referral_date, creation_date) desc, referral_id desc) = 1
)
select
  md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(date_month_start as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(date_month_end as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(referral_team as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(referral_program as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as clinical_program_referral_skey,
  date_month_start,
  date_month_end,
  referral_team,
  referral_program,
  suvida_id,
  referral_body_text,
  referral_diagnoses,
  creation_date,
  signed_date,
  referral_date,
  processing_status,
  resolution_state,
  iff(lag(suvida_id) over (partition by referral_team, suvida_id order by date_month_start) is null, true,false) as is_newly_referred
from deduped
order by date_month_start
    )
;


  