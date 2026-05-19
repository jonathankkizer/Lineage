
  
    

create or replace transient table dw_dev.dev_jkizer.patient_monthly_quality
    copy grants
    
    
    as (with time_period as (
	select
		date_month as period_start_date,
		last_day(date_month) as period_end_date
	from dw_dev.dev_jkizer.dim_date
	where is_bom
	and date_month between dateadd(month, -12, current_date()) and current_date()
), latest_part_c_quality_per_month as (
	select 
		pqm.suvida_id,
		pqm.quality_measure,
		pqm.measure_status,
		date_trunc(month, pqm.report_date) as report_month,
		pqm.measure_year,
		iff(pqm.measure_year_report_rank = 1, true, false) as is_measure_year_current_report,
		pqm.measure_year_report_rank as rn,
		dense_rank() over (partition by measure_source, date_trunc(month, pqm.report_date) order by pqm.report_date desc) as month_rn,
	from dw_dev.dev_jkizer.fct_quality_measure pqm
	where year(measure_year) >= year(dateadd(month, -12, current_date()))
), latest_med_adh_quality_per_month as (
	select 
		fma.suvida_id,
		fma.quality_measure,
		fma.measure_status,
		fma.perc_days_covered,
		fma.rx_name,
		fma.is_single_fill,
		fma.last_fill_day_supply,
		date_trunc(month, fma.report_date) as report_month,
		fma.measure_year,
		iff(fma.measure_year_report_rank = 1, true, false) as is_measure_year_current_report,
		fma.measure_year_report_rank as rn,
		dense_rank() over (partition by measure_source, date_trunc(month, fma.report_date) order by fma.report_date desc) as month_rn,
	from dw_dev.dev_jkizer.fct_med_adherence fma
	where year(measure_year) >= year(dateadd(month, -12, current_date()))
), quality_with_periods as (
	select
		tp.period_start_date,
		lq.suvida_id,
		lq.quality_measure,
		lq.measure_status,
		lq.report_month,
		lq.measure_year,
		lq.is_measure_year_current_report
	from time_period tp
	cross join latest_part_c_quality_per_month lq
	where lq.month_rn = 1
	and (
		-- Current year match
		year(lq.measure_year) = year(tp.period_start_date)
		or
		-- Carryforward logic: allow prior year data in Jan-Mar if no current year data exists
		(
			year(lq.measure_year) = year(tp.period_start_date) - 1
			and month(tp.period_start_date) <= 3
		)
	)
	and lq.report_month <= tp.period_start_date
	and (
		(lq.is_measure_year_current_report = false and year(lq.measure_year) = year(tp.period_start_date))
		or
		(lq.is_measure_year_current_report = true and year(lq.measure_year) = year(lq.report_month))
		or
		-- Allow prior year's most recent report during carryforward period
		(
			year(lq.measure_year) = year(tp.period_start_date) - 1
			and month(tp.period_start_date) <= 3
		)
	)
), med_adh_with_periods as (
	select
		tp.period_start_date,
		lq.suvida_id,
		lq.quality_measure,
		lq.measure_status,
		lq.perc_days_covered,
		lq.rx_name,
		lq.last_fill_day_supply,
		lq.is_single_fill,
		lq.report_month,
		lq.measure_year,
		lq.is_measure_year_current_report
	from time_period tp
	cross join latest_med_adh_quality_per_month lq
	where month_rn = 1 and
		(
		-- Current year match
		year(lq.measure_year) = year(tp.period_start_date)
		or
		-- Carryforward logic: allow prior year data in Jan-Mar if no current year data exists
		(
			year(lq.measure_year) = year(tp.period_start_date) - 1
			and month(tp.period_start_date) <= 3
		)
	)
	and lq.report_month <= tp.period_start_date
	and (
		(lq.is_measure_year_current_report = false and year(lq.measure_year) = year(tp.period_start_date))
		or
		(lq.is_measure_year_current_report = true and year(lq.measure_year) = year(lq.report_month))
		or
		-- Allow prior year's most recent report during carryforward period
		(
			year(lq.measure_year) = year(tp.period_start_date) - 1
			and month(tp.period_start_date) <= 3
		)
	)
), quality_with_ranking as (
	select
		*,
		row_number() over (
			partition by period_start_date, suvida_id, quality_measure
			order by year(measure_year) desc, report_month desc
		) as latest_rn
	from quality_with_periods
), med_adh_with_ranking as (
	select
		*,
		row_number() over (
			partition by period_start_date, suvida_id, quality_measure
			order by year(measure_year) desc, report_month desc
		) as latest_rn,
	from med_adh_with_periods
	qualify row_number() over (
		partition by period_start_date, suvida_id, quality_measure
		order by year(measure_year) desc, report_month desc
	) = 1
), quality_dataset as (
	select 
		period_start_date,
		suvida_id,
		quality_measure,
		measure_status
	from quality_with_ranking
	where latest_rn = 1
), pivoted_quality as (
	select *
	from quality_dataset
	pivot ( min(measure_status) for quality_measure in
		('Adult Immunization Status - Flu (Current Year)','Adult Immunization Status - Pneumo','Advanced Directive','Breast Cancer Screening','Care for Older Adults - Functional Status','Care for Older Adults - Medication Review','Colorectal Cancer Screening','Concurrent Use of Opioids and Benzodiazepines','Controlling Blood Pressure','Diabetes Care - Blood Sugar Controlled','Diabetes Care - Eye Exam','Diabetes Care - Kidney Disease Evaluation','Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)','Med Adherence - Diabetes','Med Adherence - RAS','Med Adherence - Statins','Osteoporosis Management Women who had Fx','PCP Office Visit','Plan All-Cause Readmissions','Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults','Polypharmacy: Use of Multiple CNS-Active Medications in Older Adults','Statin Therapy for Cardiovascular Disease','Statin Use in Persons with Diabetes','TRC - Medication Reconciliation Post-Discharge','TRC - Notification of Inpatient Admission','TRC - Patient Engagement after Inpatient Discharge','TRC - Patient Engagement within 7 Days after Inpatient Discharge','TRC - Receipt of Discharge Information','Transitions of Care (average)','Zephyr')
	) as p (period_start_date, suvida_id, ais_i_status,ais_p_status,adv_dir_status,bcs_status,fsa_status,coa_mdr_status,col_status,cob_status,cbp_status,hbd_status,eed_status,ked_status,fmc_status,mad_status,mah_status,mac_status,omw_status,pcpov_status,pcr_status,poly_ach_status,poly_cns_status,spc_status,supd_status,mrp_status,nia_status,ped_status,pe7_status,rdi_status,trc_avg_status,zephyr_status)
), quality_with_med_adh as (
	select
		suvida_id,
		period_start_date,
		pq.* exclude (suvida_id, period_start_date),
		max(iff(mar.quality_measure = 'Med Adherence - Statins', mar.measure_status, null)) as med_adh_statins_status,
		max(iff(mar.quality_measure = 'Med Adherence - Statins', mar.is_single_fill, null)) as med_adh_statins_single_fill_status,
		max(iff(mar.quality_measure = 'Med Adherence - Statins', mar.perc_days_covered, null)) as med_adh_statins_pdc,
		max(iff(mar.quality_measure = 'Med Adherence - Statins', mar.rx_name, null)) as med_adh_statins_rx,
		max(iff(mar.quality_measure = 'Med Adherence - Statins', mar.last_fill_day_supply, null)) as med_adh_statins_day_supply,
		max(iff(mar.quality_measure = 'Med Adherence - RAS', mar.measure_status, null)) as med_adh_ras_status,
		max(iff(mar.quality_measure = 'Med Adherence - RAS', mar.is_single_fill, null)) as med_adh_ras_single_fill_status,
		max(iff(mar.quality_measure = 'Med Adherence - RAS', mar.perc_days_covered, null)) as med_adh_ras_pdc,
		max(iff(mar.quality_measure = 'Med Adherence - RAS', mar.rx_name, null)) as med_adh_ras_rx,
		max(iff(mar.quality_measure = 'Med Adherence - RAS', mar.last_fill_day_supply, null)) as med_adh_ras_day_supply,
		max(iff(mar.quality_measure = 'Med Adherence - Diabetes', mar.measure_status, null)) as med_adh_diabetes_status,
		max(iff(mar.quality_measure = 'Med Adherence - Diabetes', mar.is_single_fill, null)) as med_adh_diabetes_single_fill_status,
		max(iff(mar.quality_measure = 'Med Adherence - Diabetes', mar.perc_days_covered, null)) as med_adh_diabetes_pdc,
		max(iff(mar.quality_measure = 'Med Adherence - Diabetes', mar.rx_name, null)) as med_adh_diabetes_rx,
		max(iff(mar.quality_measure = 'Med Adherence - Diabetes', mar.last_fill_day_supply, null)) as med_adh_diabetes_day_supply,
	from pivoted_quality pq 
	full outer join med_adh_with_ranking mar 
		using (suvida_id, period_start_date)
	group by all
), quality_engine_stages as (
	select
		suvida_id,
		quality_measure,
		iff(quality_measure not in ('Med Adherence - Diabetes', 'Med Adherence - RAS', 'Med Adherence - Statins'), stage_name, progress_bar) as stage,
	from dw_dev.dev_jkizer_quality.quality_process_measures
	where latest_rank_overall = 1
	and measure_year = year(current_date())
), pivoted_quality_engine_stages as (
	select * 
	from quality_engine_stages
	pivot (min(stage) for quality_measure in
		('Breast Cancer Screening','Care for Older Adults - Functional Status','Care for Older Adults - Medication Review','Colorectal Cancer Screening','Controlling Blood Pressure','Diabetes Care - Blood Sugar Controlled','Diabetes Care - Eye Exam','Diabetes Care - Kidney Disease Evaluation','Osteoporosis Management Women who had Fx','PCP Office Visit','Statin Therapy for Cardiovascular Disease','Statin Use in Persons with Diabetes','Zephyr', 'Med Adherence - Diabetes', 'Med Adherence - RAS', 'Med Adherence - Statins')
	) as p (suvida_id, bcs_qe_stage,fsa_qe_stage,coa_mdr_qe_stage,col_qe_stage,cbp_qe_stage,hbd_qe_stage,eed_qe_stage,ked_qe_stage,omw_qe_stage,pcpov_qe_stage,spc_qe_stage,supd_qe_stage,zephyr_qe_stage, mad_qe_stage, mah_qe_stage, mac_qe_stage)
), combined_data as (
	select
		md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(period_start_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_period_skey,
		iff(period_start_date = date_trunc(month, current_date()), true, false) as is_current_month,
		*
	from quality_with_med_adh
)
select
	cd.*,
	pqm_bp.workflow_status_detail as cbp_workflow_status_detail,
	pqm_dm.workflow_status_detail as hbd_workflow_status_detail,
	pqm_bp.workflow_note as cbp_workflow_note,
	pqm_dm.workflow_note as hbd_workflow_note,
	iff(cd.is_current_month = true, pqes.bcs_qe_stage, null) as bcs_qe_stage,
	iff(cd.is_current_month = true, pqes.fsa_qe_stage, null) as fsa_qe_stage,
	iff(cd.is_current_month = true, pqes.coa_mdr_qe_stage, null) as coa_mdr_qe_stage,
	iff(cd.is_current_month = true, pqes.col_qe_stage, null) as col_qe_stage,
	iff(cd.is_current_month = true, pqes.cbp_qe_stage, null) as cbp_qe_stage,
	iff(cd.is_current_month = true, pqes.hbd_qe_stage, null) as hbd_qe_stage,
	iff(cd.is_current_month = true, pqes.eed_qe_stage, null) as eed_qe_stage,
	iff(cd.is_current_month = true, pqes.ked_qe_stage, null) as ked_qe_stage,
	iff(cd.is_current_month = true, pqes.omw_qe_stage, null) as omw_qe_stage,
	iff(cd.is_current_month = true, pqes.pcpov_qe_stage, null) as pcpov_qe_stage,
	iff(cd.is_current_month = true, pqes.spc_qe_stage, null) as spc_qe_stage,
	iff(cd.is_current_month = true, pqes.supd_qe_stage, null) as supd_qe_stage,
	iff(cd.is_current_month = true, pqes.zephyr_qe_stage, null) as zephyr_qe_stage,
	iff(cd.is_current_month = true, pqes.mad_qe_stage, null) as mad_qe_stage,
	iff(cd.is_current_month = true, pqes.mah_qe_stage, null) as mah_qe_stage,
	iff(cd.is_current_month = true, pqes.mac_qe_stage, null) as mac_qe_stage
from combined_data cd
left join dw_dev.dev_jkizer.patient_quality_measure pqm_bp
	on cd.suvida_id = pqm_bp.suvida_id
	and pqm_bp.quality_measure = 'Controlling Blood Pressure'
	and year(pqm_bp.measure_year) = year(cd.period_start_date)
	and pqm_bp.is_measure_year_current_report = true
	and pqm_bp.patient_report_rank = 1
	and cd.is_current_month = true
left join dw_dev.dev_jkizer.patient_quality_measure pqm_dm
	on cd.suvida_id = pqm_dm.suvida_id
	and pqm_dm.quality_measure = 'Diabetes Care - Blood Sugar Controlled'
	and year(pqm_dm.measure_year) = year(cd.period_start_date)
	and pqm_dm.is_measure_year_current_report = true
	and pqm_dm.patient_report_rank = 1
	and cd.is_current_month = true
left join pivoted_quality_engine_stages pqes
	on cd.suvida_id = pqes.suvida_id
	and cd.is_current_month = true
group by all
    )
;


  