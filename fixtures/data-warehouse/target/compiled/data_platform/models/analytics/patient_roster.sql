with 

devoted_plan_names_cte (member_id, plan_name_alias) as (
    select
        member_id, 
        case
            when Charindex('Houston', plan_name) > 0 then 'Devoted-Houston'
            when Charindex('Austin', plan_name) > 0 then 'Devoted-Austin'
            when Charindex('San Antonio', plan_name) > 0 then 'Devoted-San Antonio'
			when CharIndex('Arizona', plan_name) > 0 then 'Devoted Health - Arizona'
	    end as plan_name_alias
    from
    (
        select *, Row_number() over (partition by member_id order by report_date desc) as RowID
	    from 
		(
            select report_date, member_id, plan_name
			from dw_dev.dev_jkizer_staging.stg_devoted_enrollment
        ) as tbl1
	) as tbl2
    where RowID = 1
), devoted_lang_pref as (
	select member_id, 
		iff(lower(language_preference) = 'spanish', 'Spanish; Castilian', initcap(language_preference)) as preferred_language,
		row_number() over (partition by member_id order by report_date desc) as _rn
	from dw_dev.dev_jkizer_staging.stg_devoted_enrollment
	order by report_date desc
), wellmed_lang_pref as (
	select member_id,
		iff(lower(language_preference) = 'spanish', 'Spanish; Castilian', initcap(language_preference)) as preferred_language,
		row_number() over (partition by member_id order by report_date desc) as _rn
	from dw_dev.dev_jkizer_staging.stg_wellmed_enrollment
	order by report_date desc
), devoted_insurance_id as (
	select 
		member_id, 
		plan_name_alias, 
		aliases, 
		insurance_company_id, 
		row_number() over (partition by member_id order by insurance_company_id) as _rn
	from devoted_plan_names_cte as dplc
	inner join dw_dev.dev_jkizer_staging.stg_elation_insurance_company as ins
		on dplc.plan_name_alias = ins.aliases
), other_insurance_id as (
	select 
		aliases,
		insurance_company_id,
		row_number() over (partition by aliases order by insurance_company_id) as _rn
	from dw_dev.dev_jkizer_staging.stg_elation_insurance_company as ins
)

select 
	elation_id,
	payer_member_id,
	payer_name,
	initcap(first_name) as first_name,
	initcap(last_name) as last_name,
	case
        when middle_name is not null then middle_name
        when middle_initial is not null then middle_initial
        else null
    end as middle_name,
	birth_date as dob,
	case 
		when gender = 'f' then 'Female'
		when gender = 'm' then 'Male'
		else 'Unknown'
	end as sex,
	address_line_1 as address_line1,
	address_line_2 as address_line2,
	cts.city_name as city,
	cts.state_code as state,
	zip,
    eligibility_start_month,
    trim(cast(provider_npi as nvarchar(20))) as primary_care_provider_npi,
	'509680731226116' as caregiver_practice,
    'Suvida Healthcare NPHO' as pcp_tin_name,
	race,
	ethnicity,
	marital_status,
	phone as phone1,
    'Main' as phone1_type,
    email,
	case
		when payer_name = 'Devoted' then dlp.preferred_language
		when payer_name = 'UHG/Wellmed' then wlp.preferred_language
	end as preferred_language,
	case
		when payer_name = 'Devoted' then dii.insurance_company_id
		else oii.insurance_company_id
	end as insurance_company
from dw_dev.dev_jkizer.dim_patient pt
left join source_prod.misc.src_misc_cities cts 
	on trim(city) = lower(cts.city_name)
left join devoted_lang_pref dlp 
	on pt.payer_member_id = dlp.member_id
	and dlp._rn = 1
left join wellmed_lang_pref wlp 
	on pt.payer_member_id = wlp.member_id
	and wlp._rn = 1
left join devoted_insurance_id dii
	on pt.payer_member_id = dii.member_id
	and dii._rn = 1
left join other_insurance_id oii 
	on pt.payer_name = oii.aliases
	and oii._rn = 1
where
	elation_id is not null and 
	elation_status = 'active' and 
    eligibility_start_month is not null and 
	is_active_enrollment = 1