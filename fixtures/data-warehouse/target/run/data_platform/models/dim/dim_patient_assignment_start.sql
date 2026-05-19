
  
    

create or replace transient table dw_dev.dev_jkizer.dim_patient_assignment_start
    copy grants
    
    
    as (with devoted_acq as (
	select
		de.member_id,
		de.source,
		iff(de.pcp_start_date = date(sd.pcp_payer_start_date), 'Inorganic', 'Organic') as patient_acquisition_type,
		effective_date as eligibility_start_month,
		row_number() over (partition by member_id order by report_date asc) as _idx -- 1 will be first record
	from dw_dev.dev_jkizer_staging.stg_devoted_enrollment de
	left join dw_dev.dev_jkizer_source.map_inorganic_provider_insurance_start_date sd
		on de.pcp_npi = sd.npi
		and de.source = sd.payer_name
), wellcare_acq as ( -- something is up with this logic undercounts
	select 
		we.member_id,
		we.source,
		case
			when we.effective_date = date(sd.pcp_payer_start_date)
			then 'Inorganic' else 'Organic'
		end as patient_acquisition_type,
		we.effective_date as eligibility_start_month,
		row_number() over (partition by member_id order by report_date asc) as _idx -- 1 will be first record
	from dw_dev.dev_jkizer_staging.stg_wellcare_enrollment we
	left join dw_dev.dev_jkizer_source.map_inorganic_provider_insurance_start_date sd
		on we.provider_first_name = sd.provider_first_name
		and we.provider_last_name = sd.provider_last_name
		and we.source = sd.payer_name
), wellmed_acq as (
	select 
		wme.member_id,
		wme.source,
		case
			when wme.enrollment_start_date = date(sd.pcp_payer_start_date)
			then 'Inorganic' else 'Organic'
		end as patient_acquisition_type,
		enrollment_start_date as eligibility_start_month,
		row_number() over (partition by member_id order by report_date asc) as _idx -- 1 will be first record
	from dw_dev.dev_jkizer_staging.stg_wellmed_enrollment wme
	left join dw_dev.dev_jkizer_source.map_inorganic_provider_insurance_start_date sd
		on wme.pcp_npi = sd.npi
		and wme.source = sd.payer_name
), united_acq as (
	select 
		wme.member_id,
		wme.source,
		case
			when wme.enrollment_effective_date = date(sd.pcp_payer_start_date)
			then 'Inorganic' else 'Organic'
		end as patient_acquisition_type,
		enrollment_effective_date as eligibility_start_month,
		row_number() over (partition by member_id order by report_date asc) as _idx -- 1 will be first record
	from dw_dev.dev_jkizer_staging.stg_united_az_enrollment wme
	left join dw_dev.dev_jkizer_source.map_inorganic_provider_insurance_start_date sd
		on wme.pcp_npi = sd.npi
		and wme.source = sd.payer_name
), acq_union as (
	select
		*
	from devoted_acq
	union all
	select 
		*
	from wellcare_acq
	union all
	select
		*
	from wellmed_acq
	union all
	select
		*
	from united_acq
)
select 
	suvida_id,
	min(patient_acquisition_type) as patient_acquisition_type, -- aggregate to handle case where patient jumps around payers if once inorganic, always inorganic
	min(eligibility_start_month) as eligibility_start_month,
	datediff(month, min(eligibility_start_month), current_date()) as num_months_since_eligibility_acquisition
from acq_union au 
inner join dw_dev.dev_jkizer.suvida_id_walk siw 
	on au.member_id = siw.member_id
	and au.source = siw.source
group by suvida_id
    )
;


  