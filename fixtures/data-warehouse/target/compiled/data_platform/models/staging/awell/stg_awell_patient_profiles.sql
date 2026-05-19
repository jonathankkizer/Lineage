select 
    id as patient_profile_id,
    name as full_name,
    first_name,
    last_name,
    email,
    date(birth_date) as birth_date,
    sex,
    
    case 
        when lower(trim(preferred_language)) in ('english') then 'English'
        when lower(trim(preferred_language)) in ('spanish', 'spanish; castilian') then 'Spanish'
        when lower(trim(preferred_language)) in ('portuguese') then 'Portuguese'  
        when lower(trim(preferred_language)) in ('vietnamese') then 'Vietnamese'
        when lower(trim(preferred_language)) in ('french') then 'French'
        when lower(trim(preferred_language)) in ('lao') then 'Lao'
        when lower(trim(preferred_language)) in ('sign languages') then 'American Sign Language'
        when lower(trim(preferred_language)) in ('nauru') then 'Nauruan'
        when lower(trim(preferred_language)) in ('latin') then 'Latin'
        when lower(trim(preferred_language)) in ('undetermined', '') or preferred_language is null then 'Not Specified'
        else initcap(trim(preferred_language))
    end
 as preferred_language, 
    national_registry_number,
    identifiers,
    regexp_substr(identifiers, '[0-9]+') as elation_id,
    phone,
    mobile_phone,
    address_street,
    address_city,
    address_zip,
    address_state,
    address_country,
    last_synced_at,
    status
    from source_prod.awell.patient_profiles