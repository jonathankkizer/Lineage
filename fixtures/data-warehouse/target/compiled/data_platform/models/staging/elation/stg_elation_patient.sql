select
	pt.UQ_PATIENT as uq_patient,
	'Elation' as source,
	to_varchar(pt.ID) as elation_id,
	pt.MASTER_ID as master_id,
	lower(pt.FIRST_NAME) as first_name,
	lower(pt.LAST_NAME) as last_name,
	nullif(lower(pt.MIDDLE_NAME), '') as middle_name,
	lower(pt.full_name) as preferred_name,
	nullif(left(lower(pt.MIDDLE_NAME), 1), '') as middle_initial,
	nullif(pt.SUFFIX, '') as suffix,
	nullif(pt.PREFIX, '') as prefix,
	date(pt.DOB) as birth_date,
	pt.deceased_date,
	case 
		when lower(pt.GENDER_IDENTITY) like '%female%' then 'f'
		when lower(pt.GENDER_IDENTITY) like '%male%' then 'm'
		else lower(pt.SEX)
	end as gender_sex,
	lower(pt.SEX) as sex,
	case 
		when lower(pt.GENDER_IDENTITY) like '%female%' then 'f'
		when lower(pt.GENDER_IDENTITY) like '%male%' then 'm'
		else lower(pt.gender_identity)
	end as gender,
	pt.SEXUAL_ORIENTATION as sexual_orientation,
	iff(pt.ssn is not null and pt.ssn != '', true, false) as is_ssn_available,
	pt.MARITAL_STATUS as marital_status,
	pt.OCCUPATION as occupation,
	
    case 
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('english') then 'English'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('spanish', 'spanish; castilian') then 'Spanish'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('portuguese') then 'Portuguese'  
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('vietnamese') then 'Vietnamese'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('french') then 'French'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('lao') then 'Lao'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('sign languages') then 'American Sign Language'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('nauru') then 'Nauruan'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('latin') then 'Latin'
        when lower(trim(pt.PREFERRED_LANGUAGE)) in ('undetermined', '') or pt.PREFERRED_LANGUAGE is null then 'Not Specified'
        else initcap(trim(pt.PREFERRED_LANGUAGE))
    end
 as preferred_language,
	case when lower(pt.PREFERRED_LANGUAGE) like '%spanish%' then 'y' else 'n' end as spanish_preferred_ind,
	case when lower(pt.PREFERRED_LANGUAGE) like '%english%' then 'y' else 'n' end as english_preferred_ind,
	pt.PREFERRED_CONTACT as preferred_contact,
	pt.PREFERRED_NOTIFICATION as preferred_notification,
	pt.PREFERRED_SERVICE_LOCATION_ID as preferred_service_location_id,
	pt.RACE as race,
	pt.SECONDARY_RACE as secondary_race,
	pt.PRIMARY_ETHNICITY as ethnicity,
	iff(lower(pt.PRIMARY_ETHNICITY) = 'hispanic or latino', true, false) as hispanic_latino_ethnicity_ind,
	pt.verified,
	to_boolean(pt.CONSENTED) as has_data_sharing_consent,
	pt.NOTES as notes,
	pt.PRACTICE_ID as practice_id,
	pt.PRIMARY_PHYSICIAN_USER_ID as primary_physician_user_id,
	pt.PRIMARY_CARE_PROVIDER_ID as primary_care_provider_user_id,
	pt.PATIENT_STATUS as patient_status,
	pt.PATIENT_PASSPORT_USER_ID as patient_passport_user_id,
	iff(pt.patient_passport_user_id is null, false, true) as has_patient_passport,
	null as phone,
	case
		when lower(pt.EMAIL) like '%noemail%' then null
		when lower(trim(pt.EMAIL)) in ('no email', 'none', '') then null
		else lower(pt.EMAIL)
	end as email,
	nullif(replace(lower(ltrim(rtrim(pt.ADDRESS_LINE1))), '\t', ''), '') as address_line_1,
	nullif(replace(lower(ltrim(rtrim(pt.ADDRESS_LINE2))), '\t', ''), '') as address_line_2,
	lower(pt.CITY) as city,
	lower(pt.STATE) as state,
	to_varchar(pt.ZIP) as zip,
	pt.PREF_PHARMACY1_NCPDPID,
	pt.PREF_PHARMACY2_NCPDPID,
	p1.store_name as pref_pharmacy1_name,
	concat_ws(', ',
		nullif(trim(p1.address_line1), ''),
		nullif(trim(p1.address_line2), ''),
		nullif(trim(initcap(p1.city)), ''),
		nullif(trim(upper(p1.state)), ''),
		nullif(trim(p1.zip), '')
	) as pref_pharmacy1_address,
	p1.phone_primary as pref_pharmacy1_phone,
	p2.store_name as pref_pharmacy2_name,
	concat_ws(', ',
		nullif(trim(p2.address_line1), ''),
		nullif(trim(p2.address_line2), ''),
		nullif(trim(initcap(p2.city)), ''),
		nullif(trim(upper(p2.state)), ''),
		nullif(trim(p2.zip), '')
	) as pref_pharmacy2_address,
	p2.phone_primary as pref_pharmacy2_phone,
	nullif(pt.EMERGENCY_FIRST_NAME, '') as emergency_contact_first_name,
	nullif(pt.EMERGENCY_LAST_NAME, '') as emergency_contact_last_name,
	
    
    case
        when regexp_replace(nullif(pt.EMERGENCY_PHONE, ''), '[^0-9]', '') = '' then null
        when length(regexp_replace(nullif(pt.EMERGENCY_PHONE, ''), '[^0-9]', '')) = 11
            and left(regexp_replace(nullif(pt.EMERGENCY_PHONE, ''), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(nullif(pt.EMERGENCY_PHONE, ''), '[^0-9]', ''), 10)
        when length(regexp_replace(nullif(pt.EMERGENCY_PHONE, ''), '[^0-9]', '')) = 10
            then regexp_replace(nullif(pt.EMERGENCY_PHONE, ''), '[^0-9]', '')
        else null
    end
 as emergency_contact_phone,
	nullif(pt.EMERGENCY_ADDRESS_LINE1, '') as emergency_contact_address_line1,
	nullif(pt.EMERGENCY_ADDRESS_LINE2, '') as emergency_contact_address_line2,
	nullif(pt.EMERGENCY_CITY, '') as emergency_contact_city,
	nullif(pt.EMERGENCY_STATE, '') as emergency_contact_state,
	nullif(pt.EMERGENCY_ZIP, '') as emergency_contact_zip,
	nullif(pt.EMERGENCY_RELATIONSHIP, '') as emergency_contact_relationship,
	/*
	DEFAULT_REFERRING_PROVIDER,
	*/
	date(pt.LAST_MODIFIED) as _last_modified_date,
	pt.LAST_MODIFIED as last_modified_datetime,
	date(pt.CREATION_TIME) as _creation_date,
	pt.creation_time as _creation_datetime,
	-- CREATED_BY_USER_ID,
	date(pt.DELETION_TIME) as _deletion_date,
	pt.DELETION_TIME as deletion_datetime,
	to_boolean(case when pt.DELETION_TIME is null then 0 else 1 end) as _is_deleted_record,
	-- DELETED_BY_USER_ID,
	-- WAREHOUSE_ID,
	pt.HDB_LAST_SYNC as hdb_last_sync_datetime,
	date(pt.HDB_LAST_SYNC) as _last_sync_date,
	to_boolean(case
		when pt.ID in (
			700998925156353,
			1247358770544641,
			1247365429919745,
			1247371964973057,
			1247384484708353,
			1247389746462721,
			1247413058142209
		) then 0 -- Allow specific test patients through for testing purposes
		when lower(pt.first_name) like '%suvida%' or lower(pt.last_name) like '%suvida%' or lower(pt.first_name) like '%test%' or lower(pt.last_name) like '%test%' then 1
		else 0
	end) as _is_test_patient,
	row_number() over (partition by pt.ID order by pt.HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient pt
left join dw_dev.dev_jkizer_staging.stg_elation_pharmacy p1 
	on pt.PREF_PHARMACY1_NCPDPID = p1.ncpdp_id 
	and p1._idx = 1
left join dw_dev.dev_jkizer_staging.stg_elation_pharmacy p2 
	on pt.PREF_PHARMACY2_NCPDPID = p2.ncpdp_id 
	and p2._idx = 1
where pt.DELETION_TIME is null