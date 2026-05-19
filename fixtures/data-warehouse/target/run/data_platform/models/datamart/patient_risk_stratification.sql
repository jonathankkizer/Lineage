
  
    

create or replace transient table dw_dev.dev_jkizer.patient_risk_stratification
    copy grants
    
    
    as (with risk_stratification as (
    select
        suvida_id,
        model_type,
        risk_level,
        closed_loop_run_date
    from dw_dev.dev_jkizer.fct_risk_stratification 
    group by all
), 

risk_strat_pivot as (
    select 
        $1 as suvida_id, -- refer to index position due to casing; same as saying "select 1st column"
        $2 as closed_loop_run_date,
        $3 as readmission_risk_level,
        $4 as ed_utilizer_risk_level,
        $5 as unplanned_admission_risk_level,
        $6 as dialysis_risk_level,
        $7 as mortality_risk_level
    from risk_stratification rs
        pivot(max(risk_level) for model_type in ('readmission','ed_utilizer','unplanned_admission','dialysis','mortality')) as p
),

--census is used to calculate readmissions in high risk patient logic 
census_admits_rolling_12 as (
	select
		suvida_id,
		sum(is_inpatient) as census_rolling_12_ip_admit,
		sum(is_er) as census_rolling_12_er_event,
	from dw_dev.dev_jkizer.patient_census_event pce
	where rolling_12_flag = 1
	group by suvida_id
)

-- only include updated high risk patients logic below:
select 
    md5(cast(coalesce(cast(pv.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pv.closed_loop_run_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as risk_strat_skey,
    pv.*,  
    tag.tag_value as elation_patient_tag,
    1 as high_risk_patient,
    max(encounter_date) as last_pcp_appt_date_from_index, 
    case when datediff(day, max(encounter_date), closed_loop_run_date) <= 30 then true else false end as is_hr_patient_pcp_visit_within_30days,
    datediff(day, max(encounter_date), closed_loop_run_date) days_since_last_pcp_visit
from risk_strat_pivot pv
--if patients have #HRH elation tag, they should also be counted as high risk 
left join dw_dev.dev_jkizer.fct_patient_tag tag on tag.suvida_id = pv.suvida_id 
    and pv.closed_loop_run_date between tag.creation_datetime and ifnull(tag.deletion_datetime, current_date()) 
    and lower(tag.tag_value) like '%hrh%'
-- look BACK 30 days from index date for a PCP visit  
left join dw_dev.dev_jkizer.fct_procedure  fct on fct.suvida_id = pv.suvida_id 
    and encounter_date <= closed_loop_run_date and is_pcp = 1
left join census_admits_rolling_12 car
	on pv.suvida_id = car.suvida_id
where 
    ((
        unplanned_admission_risk_level in ('Level 4', 'Level 5') 
        or mortality_risk_level = 'Level 5' 
        or readmission_risk_level = 'Level 5'
    )
    and (
        car.census_rolling_12_ip_admit > 0 
        or car.census_rolling_12_er_event > 1
    ))
    or tag.tag_value is not null
	or (car.census_rolling_12_ip_admit > 2 or car.census_rolling_12_er_event > 2) 
group by all
    )
;


  