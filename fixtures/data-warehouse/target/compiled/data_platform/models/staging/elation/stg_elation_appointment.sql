with timezone_conversion as (
	select 
		UQ_APPOINTMENT, 
		convert_timezone('America/Chicago', TIMESTAMP_TZ_FROM_PARTS(year(appt_time), month(appt_time), day(appt_time), hour(appt_time), minute(appt_time), second(appt_time), 000000000, 'America/Los_Angeles')) as appointment_datetime_ct,
		convert_timezone('UTC', convert_timezone('America/Chicago', TIMESTAMP_TZ_FROM_PARTS(year(appt_time), month(appt_time), day(appt_time), hour(appt_time), minute(appt_time), second(appt_time), 000000000, 'America/Los_Angeles'))) AS appointment_datetime_ct_utc,
		convert_timezone('America/Phoenix', TIMESTAMP_TZ_FROM_PARTS(year(appt_time), month(appt_time), day(appt_time), hour(appt_time), minute(appt_time), second(appt_time), 000000000, 'America/Los_Angeles')) as appointment_datetime_phoenix,
		convert_timezone('UTC', convert_timezone('America/Phoenix', TIMESTAMP_TZ_FROM_PARTS(year(appt_time), month(appt_time), day(appt_time), hour(appt_time), minute(appt_time), second(appt_time), 000000000, 'America/Los_Angeles'))) AS appointment_datetime_phoenix_utc
	from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.appointment app
),

elation_appt_data as (
	select
		app.UQ_APPOINTMENT as uq_appointment,
		app.ID as appointment_id,
		to_varchar(app.PATIENT_ID) as elation_id,
		app.PRACTICE_ID as practice_id,
		app.appt_time as original_datetime,
		case 
			when loc.state = 'TX' then appointment_datetime_ct 
			when loc.state = 'AZ' then appointment_datetime_phoenix 
			else appointment_datetime_ct
		end as appointment_datetime,
		case 
			when loc.state = 'TX' then appointment_datetime_ct_utc 
			when loc.state = 'AZ' then appointment_datetime_phoenix_utc 
			else appointment_datetime_ct_utc
		end as appointment_datetime_utc,
		to_date(app.appt_time) as appointment_date,		
		case 
			when loc.state = 'TX' then to_time(appointment_datetime_ct) 
			when loc.state = 'AZ' then to_time(appointment_datetime_phoenix)
			else to_time(appointment_datetime_ct) 
		end as appointment_time,
		case 
			when loc.state = 'TX' then to_time(appointment_datetime_ct_utc)
			when loc.state = 'AZ' then to_time(appointment_datetime_phoenix_utc)
			else to_time(appointment_datetime_ct_utc)
		end as appointment_time_utc,
		app.PHYSICIAN_USER_ID as physician_id,
		LTRIM(REPLACE(REPLACE(app.APPT_TYPE, 'zzz',''), ' – ','-')) as appointment_type,
		app.DESCRIPTION as appointment_description,
		app.INSTRUCTIONS as appointment_instructions,
		app.DURATION as appointment_duration,
		to_date(app.LAST_MODIFIED) as last_modified_date,
		app.LAST_MODIFIED as last_modified_datetime,
		app.COPAY_AMOUNT as copay_amount,
		to_date(app.COPAY_COLLECTION_DATE) as copay_collection_date,
		app.BILLING_NOTE as billing_note,
		app.REFERRING_PROVIDER as referring_provider,
		app.REFERRING_PROVIDER_STATE as referring_provider_state,
		app.service_location_id as elation_location_id,
		app.CREATION_TIME as creation_datetime,
		to_date(app.CREATION_TIME) as creation_date, 
		app.CREATED_BY_USER_ID as created_by_user_id,
		to_date(app.DELETION_TIME) as appointment_deletion_date,
		app.DELETION_TIME as deletion_datetime,
		to_boolean(case when app.DELETION_TIME is not null then 1 else 0 end) as _is_deleted_record,
		app.DELETED_BY_USER_ID as deleted_by_user_id,
		-- WAREHOUSE_ID,
		app.HDB_LAST_SYNC as hdb_last_sync_datetime,
		date(app.HDB_LAST_SYNC) as _last_sync_date,
		row_number() over (partition by app.ID order by app.HDB_LAST_SYNC desc) as _idx,
		sep._is_test_patient
	from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.appointment app
	left join dw_dev.dev_jkizer_staging.stg_elation_patient sep 
		on app.PATIENT_ID = sep.elation_id
		and sep._idx = 1
	left join dw_dev.dev_jkizer_staging.stg_elation_service_location loc 
		on loc.service_location_id = app.service_location_id 
	left join timezone_conversion tz on tz.UQ_APPOINTMENT = app.UQ_APPOINTMENT
)
select
	*,
	row_number() over (partition by elation_id, practice_id, appointment_datetime, physician_id, appointment_type order by deletion_datetime desc, last_modified_datetime desc, creation_datetime desc) as _duplicate_appt_idx -- in rare cases, duplicates can be created with the same information/date, but different IDs
from elation_appt_data