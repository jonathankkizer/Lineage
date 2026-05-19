
  create or replace   view dw_dev.dev_jkizer.patient_roster_elation_rcm
  
  copy grants
  
  
  as (
    

with 

min_intmdt_assignment_idx as (
    select 
		siw.suvida_id,
		dmp.report_date
	from dw_dev.dev_jkizer.dim_assignment_patient dmp
	inner join dw_dev.dev_jkizer.suvida_id_walk siw 
		on dmp.member_id = siw.member_id
		and dmp.source = siw.source
	qualify dense_rank() over (partition by siw.suvida_id order by report_date desc) = 1 -- grab latest patient info
)

select
	miep_idx.report_date as "Report Date",
	to_varchar(pt.eligibility_start_month, 'yyyy-MM') as "Attribution Month",
	pt.payer_name as "Program",
	null as "Line of Business",
	pt.payer_member_id as "Master Unique Member ID",
	pt.payer_name as "Master Unique ID System",
	pt.elation_id as "Elation Member ID",
	pt.payer_member_id as "Insurance Member ID",
	pt.first_name as "Member First Name",
	pt.middle_initial as "Member Middle Initial",
	pt.last_name as "Member Last Name",
    case 
		when lower(pt.gender) in ('f', 'female') then 'Female'
		when lower(pt.gender) in ('m', 'male') then 'Male'
		else 'Unknown'
	end as "Member Gender",
	pt.birth_date as "Member Date of Birth",
	null as "ESRD Indicator",
	coalesce(
		rtrim(to_varchar(pt.provider_npi),'.0'),
		nullif(pt.payer_assigned_npi, 'Unassigned')
	) as "PCP NPI",
	eu.user_first_name as "PCP First Name",
	eu.user_last_name as "PCP Last Name",
	'509680731226116' as "Elation Practice ID",
	'882864363' as "PCP TIN",
	'Suvida Healthcare NPHO' as "PCP TIN NAME",
	null as "Group Affiliation"
from dw_dev.dev_jkizer.dim_patient pt 
left join min_intmdt_assignment_idx miep_idx
	on pt.suvida_id = miep_idx.suvida_id
left join dw_dev.dev_jkizer_staging.stg_elation_user eu 
	on coalesce(
		rtrim(to_varchar(pt.provider_npi),'.0'),
		nullif(pt.payer_assigned_npi, 'Unassigned')
	) = eu.npi 
	and eu.npi is not null
where pt.is_active_enrollment = 1
  );

