with icds as (
    select
        suvida_id,
        listagg(icd_10_code, ',') as icd_list
    from dw_dev.dev_jkizer.fct_diagnosis
    where source_type in ('emr')
    group by suvida_id
), pcp_visit_count as (
    select suvida_id, count(encounter_skey) as num_encounters
    from dw_dev.dev_jkizer.patient_encounter
    where is_pcp = 1
    group by suvida_id
)

select
    elation_id as patient_org_source_id,
    first_name as patient_first_name,
    null as patient_middle_name,
    last_name as patient_last_name,
    birth_date as patient_dob,
    case
        when gender = 'female' then 'F'
        when gender = 'male' then 'M'
        when gender = 'm' then 'M'
        when gender = 'f' then 'F'
        when gender = 'intersex/other' then 'F'
        when gender = 'unknown' then 'F'
        else 'F'
    end as patient_sex,
    phone as patient_phone,
    nullif(
        iff(ps.address_line_2 is not null, ps.address_line_1 || ' ' || ps.address_line_2, ps.address_line_1),
        ''
    ) as patient_address,
    nullif(
        case 
            when cities.city_name is not null and cities.city_name <> '' then cities.city_name
            when pa.city is not null and pa.city <> '' then pa.city
            else ps.city
        end,
        ''
    ) as patient_city,
    nullif(
        case
            when pa.state is not null and pa.state <> '' then pa.state
            when cities.state_name is not null and cities.state_name <> '' then cities.state_code
            else upper(ps.state)
        end,
        ''
    ) as patient_state,
    nullif(
        case
            when ps.zip is not null and ps.zip <> '' then substr(ps.zip, 1, 5)
            when (ps.zip is null or ps.zip = '') and pa.zip is not null and pa.zip <> '' then pa.zip
            else ps.zip
        end,
        ''
    ) as patient_zip,
    provider_name,
    provider_name as provider_group_name,
    i.icd_list as icd_codes,
    next_pcp_appt_date as next_apt_date,
    '7400a609-fe06-453f-be5e-e71ae2aa1fb6' as site_service_keys
from dw_dev.dev_jkizer.patient_summary ps
left join pcp_visit_count pvc
    using (suvida_id)
left join icds i
    using (suvida_id)
left join source_prod.misc.src_misc_cities cities
    on trim(lower(ps.city)) = lower(cities.city_name)
left join dw_dev.dev_jkizer_staging.patient_addresses pa 
	on ps.suvida_id = pa.suvida_id and
        lower(coalesce(ps.address_line_1, '')) = lower(pa.address_line_1_key) and
        lower(coalesce(ps.address_line_2, '')) = lower(pa.address_line_2_key) and
        lower(coalesce(ps.city, '')) = lower(pa.city_key) and
        lower(coalesce(ps.state, '')) = lower(pa.state_key) and
        lower(coalesce(ps.zip, '')) = lower(pa.zip_key) and
        pa.source = 'Google'
where is_active_assignment = 1
and ((year(eligibility_start_month) = year(current_date())) or 
    (year(eligibility_start_month) < year(current_date()) and num_encounters between 1 and 6))
qualify row_number() over (order by year(eligibility_start_month) desc) <= 5000
-- logic guarantees a total of 5000 patients, as we pay for 5000 and don't want to pay for more; gives preference to current year joiners, and then prior year joiners with 1-6 visits