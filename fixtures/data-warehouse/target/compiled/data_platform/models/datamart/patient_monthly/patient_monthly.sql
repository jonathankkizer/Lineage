  

with date_spine as (
	select
		date_trunc(year, date_month) as period_year,
		date_month as period_start_date,
		last_day(date_month, month) as period_end_date,
		'monthly' as period_type
	from dw_dev.dev_jkizer.dim_date
	where is_bom = 1
	and date_day <= current_date
	and date_month >= '2023-01-01'
	
	and datediff(month, date_day, current_date) <= 4
	-- CHANGE THIS NUMBER TO CHANGE HOW MANY MONTHS IT RUNS
	
), 
most_recent_mmr_raf_type as ( -- most recent MMR data for a given patient
	select
		suvida_id,
		raf_type_code,
		hcc_engine_raf_type,
		original_reason_entitlement_code,
		dual_status_bool,
		dual_benefit_code,
	from dw_dev.dev_jkizer.fct_mmr_month fmm
	where raf_type_code is not null
	and suvida_id_mmr_rank = 1 and suvida_id is not null
	qualify row_number() over (partition by suvida_id order by mmr_month desc) = 1
), 
suvida_start as ( -- Suvida start date, min of elation creation + assignment + financial membership
	select
		siw.suvida_id,
		min(date_trunc('month', _creation_date)) as elation_creation_month,
		min(fam.assignment_month) as first_assignment_month,
		min(financial_member_month) as first_financial_month,
		least_ignore_nulls(min(date_trunc('month', _creation_date)), min(fam.assignment_month), min(financial_member_month)) as suvida_start_month
	from dw_dev.dev_jkizer.suvida_id_walk siw
	left join dw_dev.dev_jkizer_staging.stg_elation_patient sep
		on sep.elation_id = siw.member_id
		and sep.source = siw.source
	left join dw_dev.dev_jkizer.fct_assignment_month fam
		on siw.member_id = fam.member_id
		and siw.source = fam.source
	left join dw_dev.dev_jkizer.patient_financial_membership pfm
		on pfm.member_id = siw.member_id
		and pfm.financial_source = siw.source
	group by all
), 
pcp_monthly as (	-- shared services status per prorgam and enrollment/eligibility type
  select
	suvida_id,
	ds.period_start_date,
	max(case when is_eligible=1 and team='pharmd' then 'eligible' else null end) as pharmd_eligible,
	max(case when is_referred=1 and team='pharmd' then 'referred' else null end) as pharmd_referred,
	max(case when is_visit_enrollment=1 and team='pharmd' then 'visit_enrolled' else null end) as pharmd_visit_enrolled,
	max(case when is_tag_enrollment=1 and team='pharmd' then 'tag_enrolled' else null end) as pharmd_tag_enrolled,
	max(case when is_eligible=1 and team='rd' then 'eligible' else null end) as rd_eligible,
	max(case when is_referred=1 and team='rd' then 'referred' else null end) as rd_referred,
	max(case when is_visit_enrollment=1 and team='rd' then 'visit_enrolled' else null end) as rd_visit_enrolled,
	max(case when is_tag_enrollment=1 and team='rd' then 'tag_enrolled' else null end) as rd_tag_enrolled,
	max(case when is_eligible=1 and team='pt' then 'eligible' else null end) as pt_eligible,
	max(case when is_referred=1 and team='pt' then 'referred' else null end) as pt_referred,
	max(case when is_visit_enrollment=1 and team='pt' then 'visit_enrolled' else null end) as pt_visit_enrolled,
	max(case when is_tag_enrollment=1 and team='pt' then 'tag_enrolled' else null end) as pt_tag_enrolled,
	max(case when is_eligible=1 and team='mh' then 'eligible' else null end) as mh_eligible,
	max(case when is_referred=1 and team='mh' then 'referred' else null end) as mh_referred,
	max(case when is_visit_enrollment=1 and team='mh' then 'visit_enrolled' else null end) as mh_visit_enrolled,
	max(case when is_tag_enrollment=1 and team='mh' then 'tag_enrolled' else null end) as mh_tag_enrolled
  from date_spine ds
  join dw_dev.dev_jkizer.patient_clinical_program p
    on p.date_month_start = ds.period_start_date
  group by suvida_id, period_start_date
), 
patient_tags as (
    select
        ds.period_start_date,
        ds.period_end_date,
        fpt.suvida_id,
        listagg(fpt.tag_value, ' | ') within group (order by fpt.tag_value) as tag_list
    from date_spine ds
    cross join dw_dev.dev_jkizer.fct_patient_tag fpt
    where fpt.creation_datetime <= ds.period_end_date  -- Tag was created before/during period
      and coalesce(fpt.deletion_datetime, '2099-12-31') >= ds.period_start_date  -- Tag still active OR
           or fpt.deletion_datetime >= ds.period_start_date  -- Tag deleted after period started
    group by ds.period_start_date, ds.period_end_date, fpt.suvida_id
),
census_admits_rolling_12 as (
	select
		suvida_id,
		period_end_date,
		sum(iff(admit_date between dateadd(month, -3, period_end_date) and period_end_date, is_inpatient, 0)) as census_rolling_3_ip_admit,
		sum(iff(admit_date between dateadd(month, -6, period_end_date) and period_end_date, is_inpatient,0)) as census_rolling_6_ip_admit,
		sum(iff(admit_date >= dateadd(month, -12, period_end_date), is_inpatient, 0)) as census_rolling_12_ip_admit,
		sum(iff(admit_date between dateadd(month, -3, period_end_date) and period_end_date, is_er, 0)) as census_rolling_3_er_event,
		sum(iff(admit_date between dateadd(month, -6, period_end_date) and period_end_date, is_er, 0)) as census_rolling_6_er_event,
		sum(iff(admit_date >= dateadd(month, -12, period_end_date), is_er, 0)) as census_rolling_12_er_event,
		sum(iff(admit_date >= dateadd(month, -12, period_end_date), is_snf, 0)) as census_rolling_12_snf_event,
		sum(iff(admit_date >= dateadd(month, -12, period_end_date), is_rehab, 0)) as census_rolling_12_rehab_event,
		sum(iff(admit_date >= dateadd(month, -12, period_end_date) and is_inpatient = 1 and days_since_prev_discharge <= 30, 1, 0)) as census_rolling_12_ip_readmit_30day,
		max(iff(is_inpatient = 1, admit_date, null)) as census_most_recent_ip_admit_date,
		max(iff(is_er = 1, admit_date, null)) as census_most_recent_er_admit_date
	from dw_dev.dev_jkizer.patient_census_event pce
	cross join date_spine 
	where admit_date <= period_end_date 
	group by 1,2
), 
risk_score as (
	select 
		suvida_id,
		period_month,
		max(iff(period_type = 'monthly', blended_e_risk_score_adj, null)) as emr_risk_score_monthly,
		max(iff(period_type = 'rolling_12_month', blended_e_risk_score_adj, null)) as emr_risk_score_rolling,
		max(iff(period_type = 'monthly', blended_ec_risk_score_adj, null)) as emr_claims_blended_risk_score_adj_monthly,
		max(iff(period_type = 'rolling_12_month', blended_ec_risk_score_adj, null)) as emr_claims_blended_risk_score_adj_rolling
	from dw_dev.dev_jkizer.fct_hcc_score
	group by 1,2
), 
risk_score_projection as (
	-- grab the risk score year projection from the last day of the prior year for the upcoming year
	select 
		suvida_id, 
		dateadd('year', 1, date_trunc('year', period_month)) as period_year,
		max(blended_ecr_risk_score_adj) as risk_score_performance_year_projection
	from dw_dev.dev_jkizer.fct_hcc_score
	where period_type = 'monthly' and period_end_date = last_day(date_trunc('year', period_month), year)
	group by 1,2 
), 
ytd_hcc_diagnoses as ( 
	select
		suvida_id,
		date_trunc('month', period_end_date) as date_month, 
		count(distinct hcc_code) as num_emr_hcc_diagnoses_monthly
	from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis
	where source_type = 'emr'
	and hcc_model = '28' 
	and period_type = 'monthly'
	group by suvida_id, date_month
), 
patient_procs_all as (
	select
		suvida_id,
		period_end_date,
		max(case when is_pcp = 1 and encounter_date >= dateadd(week, -54, date_trunc('month', period_end_date)) then 1 else 0 end) as is_active_patient,
		count(distinct case when date_part('year', encounter_date) = date_part('year', period_end_date) then encounter_skey else null end) as num_careteam_visits_ytd,
		min(case when is_pcp = 1 then encounter_date else null end) as first_pcp_appt_date,
		max(case when is_pcp = 1 then encounter_date else null end) as last_pcp_appt_date,
		count(distinct case when is_pcp = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then encounter_skey else null end) as num_pcp_visits_ytd,
		max(case when is_pcp = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then 1 else 0 end) as is_pcp_visit_complete_ytd,
		count(distinct case when is_pcp = 1 then encounter_date else null end) as cumulative_pcp_visits,
		min(case when is_mh = 1 then encounter_date else null end) as first_mh_appt_date,
		max(case when is_mh = 1 then encounter_date else null end) as last_mh_appt_date,
		count(distinct case when is_mh = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then encounter_skey else null end) as num_mh_visits_ytd,
		min(case when is_pharmacy = 1 then encounter_date else null end) as first_pharmacy_appt_date,
		max(case when is_pharmacy = 1 then encounter_date else null end) as last_pharmacy_appt_date,
		count(distinct case when is_pharmacy = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then encounter_skey else null end) as num_pharmacy_visits_ytd,
		min(case when is_rd = 1 then encounter_date else null end) as first_nutrition_appt_date,
		max(case when is_rd = 1 then encounter_date else null end) as last_nutrition_appt_date,
		count(distinct case when is_rd = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then encounter_skey else null end) as num_nutrition_visits_ytd,
		min(case when is_pt = 1 then encounter_date else null end) as first_pt_appt_date,
		max(case when is_pt = 1 then encounter_date else null end) as last_pt_appt_date,
		count(distinct case when is_pt = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then encounter_skey else null end) as num_pt_visits_ytd,
		max(case when is_awv = 1 then encounter_date else null end) as last_awv_date,
		max(case when is_awv = 1 and date_part('year', encounter_date) = date_part('year', period_end_date) then 1 else 0 end) as is_awv_complete_ytd,
		min(case when is_advance_directives = 1 then encounter_date else null end) as first_adv_dir_date,
		max(case when is_advance_directives = 1 then encounter_date else null end) as last_adv_dir_date,
		count(distinct case when is_advance_directives = 1 then encounter_skey else null end) as cumulative_adv_dir_visits
	from dw_dev.dev_jkizer.fct_procedure fct
	cross join date_spine 
	where fct.encounter_date <= period_end_date 
	group by 1,2
), 
patient_appt as (
	select
		suvida_id,
		period_start_date, 
		period_end_date,
		count(case when fa.is_pcp_appt = 1 then appointment_id else null end) as num_upcoming_pcp_visits,
		count(case when fa.is_mh_appt = 1 then appointment_id else null end) as num_upcoming_mh_visits,
		count(case when fa.is_nutrition_appt = 1 then appointment_id else null end) as num_upcoming_nutrition_visits,
		count(case when fa.is_pharmacy_appt = 1 then appointment_id else null end) as num_upcoming_pharmacy_visits,
		count(case when fa.is_pt_appt = 1 then appointment_id else null end) as num_upcoming_pt_visits,
		count(case when fa.is_ma_appt = 1 then appointment_id else null end) as num_upcoming_ma_visits,
		count(appointment_id) as num_upcoming_careteam_visits,
		min(case when fa.is_pcp_appt = 1 then appointment_date else null end) as next_pcp_appt_date,
		min(case when fa.is_mh_appt = 1 then appointment_date else null end) as next_mh_appt_date,
		min(case when fa.is_nutrition_appt = 1 then appointment_date else null end) as next_nutrition_appt_date,
		min(case when fa.is_pharmacy_appt = 1 then appointment_date else null end) as next_pharmacy_appt_date,
		min(case when fa.is_pt_appt = 1 then appointment_date else null end) as next_pt_appt_date,
		min(case when fa.is_ma_appt = 1 then appointment_date else null end) as next_ma_appt_date,
		min(appointment_date) as next_careteam_appt_date,
		max(case when fa.is_ma_appt = 1 then appointment_description else null end) as next_ma_appt_description
	from dw_dev.dev_jkizer.fct_appointment fa
	cross join date_spine 
	where fa.appointment_date >= least(period_end_date, current_date())
		and appointment_status <> 'cancelled'
	group by suvida_id, period_start_date, period_end_date
), 
non_visit_note as (
	select
		suvida_id, 
		period_start_date,
		period_end_date,
		encounter_skey,
		note_text as non_visit_note_text,
		encounter_datetime as non_visit_encounter_datetime
	from dw_dev.dev_jkizer.patient_encounter pe
	cross join date_spine 
	where pe.encounter_date <= period_end_date
	and encounter_type = 'non_visit_encounter'
	qualify row_number() over (partition by suvida_id, period_start_date order by encounter_datetime desc, signed_datetime desc) = 1
), 
non_visit_note_guia as (
	select
		suvida_id, 
		period_start_date,
		period_end_date,
		encounter_skey,
		note_text as guia_note_text,
		encounter_datetime as guia_encounter_datetime
	from dw_dev.dev_jkizer.patient_encounter pe
	cross join date_spine 
	where pe.encounter_date <= period_end_date
	and encounter_type = 'non_visit_encounter'
	and is_guia = 1
	qualify row_number() over (partition by suvida_id, period_start_date order by encounter_datetime desc, signed_datetime desc) = 1
),
risk_stratification as (
    select
        frs.suvida_id,
        ds.period_start_date,
        ds.period_end_date,
        max(case when frs.model_type = 'unplanned_admission' then frs.risk_level end) as unplanned_admission_risk_level,
        max(case when frs.model_type = 'readmission' then frs.risk_level end) as readmission_risk_level,
        max(case when frs.model_type = 'mortality' then frs.risk_level end) as mortality_risk_level
    from date_spine ds 
    inner join dw_dev.dev_jkizer.fct_risk_stratification frs
        on frs.closed_loop_run_date between ds.period_start_date and ds.period_end_date  
        and frs.model_type in ('unplanned_admission', 'readmission', 'mortality')
    group by frs.suvida_id, ds.period_start_date, ds.period_end_date
        
),
patient_monthly as (
	select
		md5(cast(coalesce(cast(dp.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ds.period_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ds.period_start_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ds.period_end_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_period_skey,
        ds.*,
        dp.suvida_id,
        dp.birth_date,
        dp.gender,
		dp.eligibility_start_month,
		dp.eligibility_max_month,
		datediff(year, dp.birth_date, date(concat('02', '01', cast(year(ds.period_start_date) as text)), 'MMDDYYYY')) as age_year,
		datediff(year, dp.birth_date, date(concat('02', '01', cast(year(ds.period_start_date) + 1 as text)), 'MMDDYYYY')) as projected_year_hcc_age_year,
		iff(greatest_ignore_nulls(fmm.dual_status_bool, mrmrt.dual_status_bool, dp.dual_status_bool) = true and age_year < 65, '1', '0') as current_reason_entitlement_code,
		iff(greatest_ignore_nulls(fmm.dual_status_bool, mrmrt.dual_status_bool, dp.dual_status_bool) = true and projected_year_hcc_age_year < 65, '1', '0') as projected_year_current_reason_entitlement_code,
		cast(cast(coalesce(iff(age_year < 65, 1, null), fmm.original_reason_entitlement_code, mrmrt.original_reason_entitlement_code, '0') as int) as varchar) as original_reason_entitlement_code,
		cast(cast(coalesce(iff(projected_year_hcc_age_year < 65, 1, null), fmm.original_reason_entitlement_code, mrmrt.original_reason_entitlement_code, '0') as int) as varchar) as projected_year_original_reason_entitlement_code,
		pca.provider_name as provider_name,
		pca.provider_npi,
		pca.location_name as location_name,
		fmm.mmr_risk_score as period_mmr_risk_score,
		fmm.dual_status_bool as period_dual_status_bool,
		mrmrt.dual_status_bool as most_recent_mmr_dual_status_bool,
		dp.dual_status_bool as assignment_dual_status_bool,
		greatest_ignore_nulls(fmm.dual_status_bool, mrmrt.dual_status_bool, dp.dual_status_bool) as dual_status_bool, -- investigate replacing or augmenting this with MMR data
		fmm.dual_benefit_code as period_dual_benefit_code,
		mrmrt.dual_benefit_code as most_recent_mmr_dual_benefit_code,
		coalesce(fmm.dual_benefit_code, mrmrt.dual_benefit_code, '00') as dual_benefit_code,
		fmm.hcc_engine_raf_type as period_hcc_engine_raf_type,
		mrmrt.hcc_engine_raf_type as most_recent_mmr_hcc_engine_raf_type,
		coalesce(fmm.hcc_engine_raf_type, -- current period MMR data
				mrmrt.hcc_engine_raf_type, -- most recent MMR data
				iff(dateadd(year, 65, dp.birth_date) >= dateadd(year, -1, last_day(ds.period_year, month)), 'NE', null), -- flag all patients who turned 65 in prior period year after 1/31 as NE
				'CNA' -- base case
				)
		as current_year_hcc_engine_raf_type,
		emr_risk_score_monthly,
		emr_risk_score_rolling,
		emr_claims_blended_risk_score_adj_monthly,
		emr_claims_blended_risk_score_adj_rolling,
		risk_score_performance_year_projection,
		num_emr_hcc_diagnoses_monthly,
		num_careteam_visits_ytd,
		ifnull(is_active_patient, 0) as is_active_patient,
		first_pcp_appt_date,
		last_pcp_appt_date,
		num_pcp_visits_ytd,
		is_pcp_visit_complete_ytd,
		cumulative_pcp_visits,
		first_mh_appt_date,
		last_mh_appt_date,
		num_mh_visits_ytd,
		first_pharmacy_appt_date,
		last_pharmacy_appt_date,
		num_pharmacy_visits_ytd,
		first_nutrition_appt_date,
		last_nutrition_appt_date,
		num_nutrition_visits_ytd,
		last_awv_date,
		is_awv_complete_ytd,
		first_pt_appt_date,
		last_pt_appt_date,
		num_pt_visits_ytd,
		first_adv_dir_date,
		last_adv_dir_date, 
		cumulative_adv_dir_visits,
		
		-- high risk patient 
		case
			when 
				(
                    rf.unplanned_admission_risk_level in ('Level 4', 'Level 5')
    				or rf.mortality_risk_level = 'Level 5'
    				or rf.readmission_risk_level = 'Level 5'
                )
    			and 
    				(
                    admits.census_rolling_12_ip_admit > 0
    				or admits.census_rolling_12_er_event > 1
                    )
    			    or lower(pt.tag_list) like '%hrh%'
    				or (admits.census_rolling_12_ip_admit > 2 or admits.census_rolling_12_er_event > 2)
    		then 1 else 0
    			end as high_risk_patient,

		-- Mis Deseos Tags 
        iff(lower(pt.tag_list) ilike '%hospice%', true, false) as hospice_tag,
        iff(lower(pt.tag_list) ilike '%Advanced Care Planning%', true, false) as adv_care_plan_tag,
    
		case
			when fmm.hcc_engine_raf_type is not null then 'mmr_month'
			when mrmrt.hcc_engine_raf_type is not null then 'most_recent_mmr_value'
			when dateadd(year, 65, dp.birth_date) >= dateadd(year, -1, last_day(ds.period_year, month)) then 'ne_recent_65'
			else 'cna_default'
		end as current_year_hcc_engine_raf_type_source,
		pcp.pharmd_eligible,
		pcp.pharmd_referred,
		pcp.pharmd_visit_enrolled,
		pcp.pharmd_tag_enrolled,
		pcp.rd_eligible,
		pcp.rd_referred,
		pcp.rd_visit_enrolled,
		pcp.rd_tag_enrolled,
		pcp.pt_eligible,
		pcp.pt_referred,
		pcp.pt_visit_enrolled,
		pcp.pt_tag_enrolled,
		pcp.mh_eligible,
		pcp.mh_referred,
		pcp.mh_visit_enrolled,
		pcp.mh_tag_enrolled,
		admits.census_rolling_3_ip_admit,
		admits.census_rolling_6_ip_admit,
		admits.census_rolling_12_ip_admit,
		admits.census_rolling_3_er_event,
		admits.census_rolling_6_er_event,
		admits.census_rolling_12_er_event,
		admits.census_rolling_12_snf_event,
		admits.census_rolling_12_rehab_event,
		admits.census_rolling_12_ip_readmit_30day,
		admits.census_most_recent_ip_admit_date,
		admits.census_most_recent_er_admit_date,
		case 
			when is_pcp_visit_complete_ytd = 1 then 1
			when pa.next_pcp_appt_date is not null and year(pa.next_pcp_appt_date) = year(ds.period_end_date) then 1
			else 0
		end as is_pcp_visit_complete_scheduled_ytd,
		coalesce(pa.num_upcoming_pcp_visits, 0) as num_upcoming_pcp_visits,
		coalesce(pa.num_upcoming_mh_visits, 0) as num_upcoming_mh_visits,
		coalesce(pa.num_upcoming_nutrition_visits, 0) as num_upcoming_nutrition_visits,
		coalesce(pa.num_upcoming_pharmacy_visits, 0) as num_upcoming_pharmacy_visits,
		coalesce(pa.num_upcoming_careteam_visits, 0) as num_upcoming_careteam_visits,
		coalesce(pa.num_upcoming_pt_visits, 0) as num_upcoming_pt_visits,
		coalesce(pa.num_upcoming_ma_visits, 0) as num_upcoming_ma_visits,
		pa.next_pcp_appt_date,
		pa.next_mh_appt_date,
		pa.next_nutrition_appt_date,
		pa.next_pharmacy_appt_date,
		pa.next_careteam_appt_date,
		pa.next_pt_appt_date,
		pa.next_ma_appt_date,
		pa.next_ma_appt_description,
		case
			when is_pcp_visit_complete_ytd = 1 then 'Visit Complete'
			when date_trunc(month, pa.next_pcp_appt_date) = ds.period_start_date then 'Scheduled - Current Month'
			when date_trunc(month, pa.next_pcp_appt_date) in (dateadd(month, 1, ds.period_start_date), dateadd(month, 2, ds.period_start_date)) then 'Scheduled - 1-2 Months Out'
			when date_trunc(month, pa.next_pcp_appt_date) >= dateadd(month, 3, ds.period_start_date) then 'Scheduled - 3+ Months Out'
		end as patient_visit_appointment_bucket,
		nvn.non_visit_note_text as recent_non_visit_note_text,
		nvn.non_visit_encounter_datetime as recent_non_visit_note_datetime,
		nvng.guia_note_text as recent_non_visit_guia_note_text,
		nvng.guia_encounter_datetime as recent_non_visit_guia_note_datetime
	from date_spine ds
	inner join dw_dev.dev_jkizer.dim_patient dp
		on 1=1
	inner join suvida_start ss
		on dp.suvida_id = ss.suvida_id
		and ds.period_start_date >= ss.suvida_start_month
	left join dw_dev.dev_jkizer.patient_care_assignment pca
		on dp.suvida_id = pca.suvida_id
		and ds.period_start_date = pca.care_assignment_month
	left join dw_dev.dev_jkizer.fct_mmr_month fmm
		on dp.suvida_id = fmm.suvida_id
		and fmm.mmr_month = ds.period_start_date
		and fmm.suvida_id_mmr_rank = 1
		and fmm.suvida_id is not null
	left join most_recent_mmr_raf_type mrmrt
		on dp.suvida_id = mrmrt.suvida_id
	left join pcp_monthly pcp
		on dp.suvida_id = pcp.suvida_id
		and ds.period_start_date = pcp.period_start_date
	left join risk_score 
		on risk_score.suvida_id = dp.suvida_id 
		and risk_score.period_month = ds.period_start_date
	left join ytd_hcc_diagnoses 
		on ytd_hcc_diagnoses.suvida_id = dp.suvida_id 
		and ytd_hcc_diagnoses.date_month = ds.period_start_date
	left join patient_procs_all ppa 
		on ppa.suvida_id = dp.suvida_id 
		and ppa.period_end_date = ds.period_end_date
	left join risk_score_projection proj
		on proj.suvida_id = dp.suvida_id 
		and proj.period_year = ds.period_year
	left join census_admits_rolling_12 admits 
		on admits.suvida_id = dp.suvida_id 
		and admits.period_end_date = ds.period_end_date
	left join patient_appt pa 
		on dp.suvida_id = pa.suvida_id
		and ds.period_end_date = pa.period_end_date
	left join non_visit_note nvn 
		on dp.suvida_id = nvn.suvida_id
		and ds.period_end_date = nvn.period_end_date
	left join non_visit_note_guia nvng
		on dp.suvida_id = nvng.suvida_id
		and ds.period_end_date = nvng.period_end_date
	left join patient_tags pt
        on dp.suvida_id = pt.suvida_id
        and ds.period_start_date = pt.period_start_date
        and ds.period_end_date = pt.period_end_date
    left join risk_stratification rf
        on  dp.suvida_id = rf.suvida_id
        and ds.period_start_date = rf.period_start_date
        and ds.period_end_date = rf.period_end_date
	group by all  	

), hcc_proj as (
	select
		*,
		coalesce(
			iff(current_year_hcc_engine_raf_type = 'NE' and dateadd(year, 66, birth_date) <= dateadd(year, 1, last_day(period_year, month)),
				'CNA',
				null),
			current_year_hcc_engine_raf_type -- if not NE flip to CNA, carry forward current year
			)
		as projected_year_hcc_engine_raf_type, -- use this for HCC algorithm (we want our projected next year score)
		case
			when current_year_hcc_engine_raf_type = 'NE' and dateadd(year, 66, birth_date) <= dateadd(year, 1, last_day(period_year, month)) then 'ne_cna_flip'
			else current_year_hcc_engine_raf_type_source
		end as projected_year_hcc_engine_raf_type_source
	from patient_monthly
)
select
	 *,
	iff(period_start_date = date_trunc(month, current_date()), true, false) as is_max_period,
	case
		when current_year_hcc_engine_raf_type = 'CND' then 'Community NonDual Disabled'
		when current_year_hcc_engine_raf_type = 'CNA' then 'Community NonDual Aged'
		when current_year_hcc_engine_raf_type = 'NE' then 'New Enrollee'
		when current_year_hcc_engine_raf_type = 'CFD' then 'Community Full Benefit Dual Disabled'
		when current_year_hcc_engine_raf_type = 'CFA' then 'Community Full Benefit Dual Aged'
		when current_year_hcc_engine_raf_type = 'CPA' then 'Community Partial Benefit Dual Aged'
		when current_year_hcc_engine_raf_type = 'CPD' then 'Community Partial Benefit Dual Disabled'
		when current_year_hcc_engine_raf_type = 'SNPNE' then 'New Enrollee Chronic Care SNP'
		when current_year_hcc_engine_raf_type = 'INS' then 'Institutional'
	end as current_year_hcc_engine_raf_description,
	case
		when projected_year_hcc_engine_raf_type = 'CND' then 'Community NonDual Disabled'
		when projected_year_hcc_engine_raf_type = 'CNA' then 'Community NonDual Aged'
		when projected_year_hcc_engine_raf_type = 'NE' then 'New Enrollee'
		when projected_year_hcc_engine_raf_type = 'CFD' then 'Community Full Benefit Dual Disabled'
		when projected_year_hcc_engine_raf_type = 'CFA' then 'Community Full Benefit Dual Aged'
		when projected_year_hcc_engine_raf_type = 'CPA' then 'Community Partial Benefit Dual Aged'
		when projected_year_hcc_engine_raf_type = 'CPD' then 'Community Partial Benefit Dual Disabled'
		when projected_year_hcc_engine_raf_type = 'SNPNE' then 'New Enrollee Chronic Care SNP'
		when projected_year_hcc_engine_raf_type = 'INS' then 'Institutional'
	end as projected_year_hcc_engine_raf_description,
from hcc_proj