
  
    

create or replace transient table dw_dev.dev_jkizer.int_quality_trc_2026
    copy grants
    
    
    as (with census_admits as (
	select 
		census_quality_grouping_id, 
		suvida_id,
		max(iff(is_er = 1, admit_date, null)) as er_visit_date,
		max(iff(census_quality_admit_index = 1, admit_date, null)) as inpatient_first_admission_date,
		max(iff(census_quality_admit_index = 1, discharge_date, null)) as inpatient_first_discharge_date,
		max(iff(census_quality_admit_index = 2, discharge_date, null)) as inpatient_second_discharge_date,
		max(iff(census_quality_admit_index = 3, discharge_date, null)) as inpatient_third_discharge_date,
		max(iff(census_quality_admit_index = 4, discharge_date, null)) as inpatient_fourth_discharge_date,
		dateadd(day, 2, max(iff(census_quality_admit_index = 1, admit_date, null))) as notification_admission_due_date,
		dateadd(day, 2, max(discharge_date)) as receipt_discharge_summary_due_date,
		dateadd(day, 7, max(discharge_date)) as patient_engagement_post_discharge_due_date,
		dateadd(day, 30, max(discharge_date)) as mrpd_due_date,
		min(first_report_date) as first_report_date,
		max(max_report_date) as max_report_date,
		listagg(distinct concat(sources, ' - ', source_types), ' | ') as notification_sources,
		listagg(distinct facilities) as facilities,
	from dw_dev.dev_jkizer.patient_census_event
	where (is_inpatient = 1 or is_er = 1)
	and census_quality_grouping_id is not null -- need to grab the others
	group by all
), trc_measure_year as (
	select
		*,
		coalesce(inpatient_fourth_discharge_date, inpatient_third_discharge_date, inpatient_second_discharge_date, inpatient_first_discharge_date, er_visit_date) as census_sorting_date,
	from census_admits
	where year(greatest_ignore_nulls(inpatient_first_discharge_date, inpatient_second_discharge_date, inpatient_third_discharge_date, inpatient_fourth_discharge_date, er_visit_date)) = 2026 -- manually set for 2025; will have to update w/ new measure year (candidate for CLEANUP/variable)
)
select
	census_quality_grouping_id,
	my.suvida_id,
	full_name,
	birth_date,
	elation_patient_url,
	coalesce(payer_member_id, elation_insurance_member_id) as payer_member_id,
	location_name,
	provider_name,
	last_pcp_appt_date,
	next_pcp_appt_date,
	coalesce(pa.assignment_payer_name, ps.payer_name, ps.elation_insurance_name) as payer_name,
	er_visit_date,
	inpatient_first_admission_date,
	inpatient_first_discharge_date,
	inpatient_second_discharge_date,
	inpatient_third_discharge_date,
	inpatient_fourth_discharge_date,
	notification_admission_due_date,
	receipt_discharge_summary_due_date,
	patient_engagement_post_discharge_due_date,
	mrpd_due_date,
	first_report_date,
	max_report_date,
	notification_sources,
	facilities,
	census_sorting_date,
from trc_measure_year my
left join dw_dev.dev_jkizer.patient_summary ps
	on my.suvida_id = ps.suvida_id
left join dw_dev.dev_jkizer.patient_assignment pa
	on my.suvida_id = pa.suvida_id
	and date_trunc(month, census_sorting_date) = pa.date_month
	and pa.assignment_month_ind = 1
    )
;


  