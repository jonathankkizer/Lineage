with agent_info as (
	select 
		Id as sf_agent_id,
		Name as agent_name,
	from airbyte_source_prod.salesforce_production.contact
	where Contact_Type__c = 'Independent Medicare Agent'
)
select
	Id as sf_contact_id,
	AccountId as sf_account_id,
	IsDeleted as is_deleted,
	IsPersonAccount as is_person_account,
	FirstName as first_name,
	LastName as last_name,
	MiddleName as middle_name,
	null as middle_initial,
	Name as full_name,
	try_to_date(Birthdate) as birth_date,
	case 
		when Birthdate is not null then 'actual' 
		when Birth_Year__c is not null then 'truncated_year'
		else 'no_birth_date'
		end
	as birth_date_type,
	floor((datediff(day, coalesce(date(Birthdate), try_to_date(concat(Birth_Year__c, '-01-01'))), current_date())) / 365.25) as age_year,
	Sex__c as gender,
	MailingStreet as address_line_1,
	null as address_line_2,
	MailingCity as city,
	MailingState as state,
	to_varchar(MailingPostalCode) as zip,
	MailingCountry as country,
	coalesce(
		
    
    case
        when regexp_replace(Phone, '[^0-9]', '') = '' then null
        when length(regexp_replace(Phone, '[^0-9]', '')) = 11
            and left(regexp_replace(Phone, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(Phone, '[^0-9]', ''), 10)
        when length(regexp_replace(Phone, '[^0-9]', '')) = 10
            then regexp_replace(Phone, '[^0-9]', '')
        else null
    end
,
		
    
    case
        when regexp_replace(MobilePhone, '[^0-9]', '') = '' then null
        when length(regexp_replace(MobilePhone, '[^0-9]', '')) = 11
            and left(regexp_replace(MobilePhone, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(MobilePhone, '[^0-9]', ''), 10)
        when length(regexp_replace(MobilePhone, '[^0-9]', '')) = 10
            then regexp_replace(MobilePhone, '[^0-9]', '')
        else null
    end
,
		
    
    case
        when regexp_replace(HomePhone, '[^0-9]', '') = '' then null
        when length(regexp_replace(HomePhone, '[^0-9]', '')) = 11
            and left(regexp_replace(HomePhone, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(HomePhone, '[^0-9]', ''), 10)
        when length(regexp_replace(HomePhone, '[^0-9]', '')) = 10
            then regexp_replace(HomePhone, '[^0-9]', '')
        else null
    end
,
		
    
    case
        when regexp_replace(OtherPhone, '[^0-9]', '') = '' then null
        when length(regexp_replace(OtherPhone, '[^0-9]', '')) = 11
            and left(regexp_replace(OtherPhone, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(OtherPhone, '[^0-9]', ''), 10)
        when length(regexp_replace(OtherPhone, '[^0-9]', '')) = 10
            then regexp_replace(OtherPhone, '[^0-9]', '')
        else null
    end

	) as phone,
	MobilePhone as mobile_phone,
	HomePhone as home_phone,
	OtherPhone as other_phone,
	Email as email,
	Source_of_Lead__c as source_of_lead,
	Originating_Lead__c as originating_lead,
	date(Enrollment_Date__c) enrollment_date,
	date(Tour_Date__c) as tour_date,
	tour_completed__c as is_tour_completed,
	try_to_date(contact_last_activity_date__c) as contact_last_activity_date,
	campaign__c,
	Stage_Contact__c as contact_stage,
	date(stage_1_start_date__c) as stage_1_start_date,
	date(stage_2_start_date__c) as stage_2_start_date,
	date(stage_3_start_date__c) as stage_3_start_date,
	date(stage_4_start_date__c) as stage_4_start_date,
	date(stage_5_start_date__c) as stage_5_start_date,
	date(stage_6_start_date__c) as stage_6_start_date,
	date(stage_7_start_date__c) as stage_7_start_date,
	Preferred_Suvida_Location__c as preferred_suvida_location,
	Preferred_Suvida_PCP__c as preferred_suvida_pcp,
	Needs_Transportation__c as needs_transportation,
	Insurance_Status__c as insurance_status,
	Insurance_ID__c as insurance_id,
	Insurance_Provider__c, -- join to the right table to pull value
	to_date(First_Appointment_Date__c) as first_suvida_appt_date,
	First_Appointment_Completed__c as first_suvida_appt_completed,
	Contact_Type__c as contact_type,
	Contact_During_AEP__c as contact_during_aep,
	Member_Source__c as member_source,
	to_timestamp(CreatedDate) as created_datetime,
	CreatedById as created_by_id,
	OwnerId as owner_id,
	to_timestamp(LastModifiedDate) as last_modified_datetime,
	LastModifiedById as last_modified_by_id,
	MRN__c as elation_id,
	how_heard_about_us__c as how_did_patient_hear_about_us,
	to_timestamp(SystemModstamp) as system_mod_timestamp,
	'SalesForce' as _source_system,
	_AIRBYTE_EXTRACTED_AT as airbyte_extracted_at,
	case 
		when siw1.suvida_id is not null then 'salesforce_mrn'
		when siw2.suvida_id is not null then 'salesforce_suvida_id'
		else 'no_suvida_id_match'
	end as suvida_id_match_type,
	coalesce(siw1.suvida_id, siw2.suvida_id) as suvida_id,
	row_number() over (partition by coalesce(siw1.suvida_id, siw2.suvida_id) order by Id asc) as suvida_id_rank,
	agencyname__c as agency_name,
	agent_of_record_form__c as agent_of_record_form,
	referral_direction__c as referral_direction,
	try_to_date(date_referred_to_agent__c) as date_referred_to_agent,
	ai.agent_name, 
	date(pcp_effective_date__c) as pcp_effective_date,
	date(enrollment_date__c) as pcp_change_date, 
	lead_resolution__c as lead_resolution,
	representative_name__c as representative_name,
	pcp_reference__c as pcp_reference_no,
from airbyte_source_prod.salesforce_production.contact sfc
left join dw_dev.dev_jkizer.suvida_id_walk siw1
	on sfc.MRN__c = siw1.member_id
	and siw1.source = 'Elation'
left join dw_dev.dev_jkizer.suvida_id_walk siw2
	on sfc.Id = siw2.member_id
	and siw2.source = 'SalesForce'
left join agent_info ai
	on sfc.CONTACT_NAME__C = ai.sf_agent_id
where len(sfc.Id) = 18 -- QA measure while load process has some faults can remove after fix is in place
and try_to_date(Birthdate) <= current_date() -- filter out future birthdays, as these are likely typos; too far future can break suvida id process