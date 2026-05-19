
  
    

create or replace transient table dw_dev.dev_jkizer.salesforce_patient_opportunity
    copy grants
    
    
    as (with salesforce_leads as ( -- grab all salesforce lead data that fits parameters from Growth team
	select
		pc.*,
		u.user_name as prospect_owner,
		u.team_name as prospect_owner_team_name,
		cp.campaign_name, 
		cp.startdate, 
		cp.enddate, 
		cp.suvida_location__c, 
		cp.campaign_type, 
		cp.event_type__c, 
		cp.status,
		campaign_contact.name as campaign_point_of_contact
	from dw_dev.dev_jkizer_staging.stg_sf_patient_contact pc
	left join dw_dev.dev_jkizer_staging.stg_sf_user u
		on pc.owner_id = u.sf_user_id
	left join dw_dev.dev_jkizer_staging.stg_sf_campaign_member cm 
		on cm.contactid = pc.sf_contact_id
	left join dw_dev.dev_jkizer_staging.stg_sf_campaign cp
		on cp.sf_campaign_id = cm.campaignid
	left join dw_dev.dev_jkizer_staging.stg_sf_user campaign_contact
		on campaign_contact.sf_user_id = cp.ownerid
	--where contact_stage != '1-New' -- exclude "New" status; 35k+ patients in this stage, many with poor information
	where contact_type in ('Suvida Prospect', 'Suvida Patient')
	and u.team_name != 'Leadership'
	qualify row_number() over (partition by suvida_id order by last_modified_datetime desc) = 1 -- grab latest record per suvida_id, guarantee suvida_id is unique
), scheduled_appt_match as ( -- find overlap between Salesforce and Elation scheduled appointments
	select
		fa.suvida_id,
		fa.appointment_date,
		fa.appointment_provider_name,
		fa.appointment_type,
		fa.appointment_description,
		fa.appointment_status,
		row_number() over (partition by fa.suvida_id order by fa.appointment_date asc) as _appt_idx
	from dw_dev.dev_jkizer.fct_appointment fa
	inner join salesforce_leads sl
		on fa.suvida_id = sl.suvida_id
	where fa.appointment_date >= sl.first_suvida_appt_date
	and appointment_provider_category = 'PCP'
), patient_encounter as ( -- understand if patients actually attended scheduled appointments
	select
		pe.suvida_id,
		pe.encounter_date,
		row_number() over (partition by pe.suvida_id order by pe.encounter_date asc) as _encounter_idx
	from dw_dev.dev_jkizer.patient_encounter pe
	inner join salesforce_leads sl
		on pe.suvida_id = sl.suvida_id
	where pe.encounter_date >= sl.first_suvida_appt_date
	and pe.encounter_type = 'clinical_encounter'
), earliest_eligibility as (
	select 
		suvida_id, 
		min(date_month) as first_eligible_month
	from dw_dev.dev_jkizer.patient_assignment pa 
	where assignment_month_ind = 1
	group by 1
)
select
	sl.suvida_id,
	sl.sf_contact_id,
	sl.elation_id as salesforce_elation_mrn_id,
	sl.first_name as sf_first_name,
	sl.last_name as sf_last_name,
	sl.birth_date as sf_birth_date,
	sl.address_line_1 as sf_address_line_1,
	sl.address_line_2 as sf_address_line_2,
	sl.city as sf_city,
	sl.state as sf_state,
	sl.zip as sf_zip,
	sl.phone as sf_phone,
	sl.suvida_id_match_type,
	sl.prospect_owner,
	sl.prospect_owner_team_name,
	sl.campaign_name,
	sl.startdate as campaign_start_date,
	sl.enddate as campaign_end_date,
	sl.suvida_location__c as suvida_location,
	sl.insurance_provider__c as insurance_provider_sf_id,
	sl.campaign_type,
	sl.event_type__c as event_type,
	campaign_point_of_contact,
	sl.status as campaign_status,
	sl.source_of_lead,
	sl.originating_lead,
	sl.how_did_patient_hear_about_us,
	case
		when (sl.how_did_patient_hear_about_us) in ('Broker Referral') then 'Broker'
		when (sl.how_did_patient_hear_about_us) in ('TV Ad', 'Radio Ad', 'Social Media', 'Google Search', 'Billboard', 'Suvida Website', 'Mailer') then 'Marketing'
		when (sl.how_did_patient_hear_about_us) in ('Event - In-Center', 'Event - Out of Center', 'Grass Roots') then 'Neighborhood Engagement'
		when (sl.how_did_patient_hear_about_us) in ('Clinic Drive-by') then 'Other'
		when (sl.how_did_patient_hear_about_us) in ('Health Plan Assignment') then 'Health Plan Assignment'
		when (sl.how_did_patient_hear_about_us) in ('Followed PCP') then 'Followed PCP'
		when (sl.how_did_patient_hear_about_us) in ('Patient Referral', 'Health Plan Referral', 'Specialist Referral', 'Referral from Care Team', 'Friend / Family Member') then 'Referral'
    	else null
	end as growth_channel,
	sl.contact_stage,
	sl.stage_1_start_date,
	sl.stage_2_start_date,
	sl.stage_3_start_date,
	sl.stage_4_start_date,
	sl.stage_5_start_date,
	sl.stage_6_start_date,
	sl.stage_7_start_date,
	sl.preferred_suvida_location,
	sl.preferred_suvida_pcp,
	sl.contact_type,
	sl.member_source,
	tour_date,
	sl.is_tour_completed,
	sl.contact_last_activity_date,
	elg.first_eligible_month,
	sl.first_suvida_appt_date as sf_first_suvida_appt_date,
	case
		when
		sl.first_suvida_appt_date = sam.appointment_date then 'TRUE' else 'FALSE'
	end as matching_scheduled_appt_found,
	case
		when
		sl.first_suvida_appt_date != sam.appointment_date then sam.appointment_date else null
	end as other_scheduled_appointment_date_found,
	case
		when
		sl.first_suvida_appt_date = pe.encounter_date then 'TRUE' else 'FALSE'
	end as matching_encounter_found,
	case
		when
		sl.first_suvida_appt_date != pe.encounter_date then pe.encounter_date else null
	end as other_encounter_date_found,
	sl.created_datetime,
	to_date(sl.created_datetime) as created_date,
	sl.last_modified_datetime,
	to_date(sl.last_modified_datetime) as last_modified_date,
	agency_name,
	agent_of_record_form,
	referral_direction,
	date_referred_to_agent,
	agent_name,
	pcp_change_date,
	pcp_effective_date,
	lead_resolution,
	representative_name,
	pcp_reference_no,
from salesforce_leads sl
left join scheduled_appt_match sam
	on sl.suvida_id = sam.suvida_id
	and _appt_idx = 1
left join patient_encounter pe
	on sl.suvida_id = pe.suvida_id
	and _encounter_idx = 1
left join earliest_eligibility elg
	on elg.suvida_id = sl.suvida_id
    )
;


  