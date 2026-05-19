with clinical_lab_values as (
    select
        suvida_id,
        period_start_date,
        period_end_date,
    
    -- BP
        most_recent_bp_date,
        most_recent_bp_systolic,
        most_recent_bp_diastolic,

    -- A1c
        most_recent_a1c_date,
        most_recent_a1c,

    -- lipids
        most_recent_hdl_date,
        most_recent_hdl,

        most_recent_ldl_date,
        most_recent_ldl,

        most_recent_triglyceride_date,
        most_recent_triglyceride,
        
        most_recent_total_cholesterol_date,
        most_recent_total_cholesterol
    from dw_dev.dev_jkizer.patient_monthly_clinical_values
    where is_current_month = 1

),

bp_a1c_days as (
    select
        pr.suvida_id,
        pr.referral_id,
        pr.referral_date,
        pmcv.most_recent_bp_date,
        pmcv.most_recent_bp,
        abs(datediff(day, pr.referral_date, pmcv.most_recent_bp_date)) as days_bp_from_referral,
        pmcv.most_recent_a1c_date,
        pmcv.most_recent_a1c,
        abs(datediff(day, pr.referral_date, pmcv.most_recent_a1c_date)) as days_a1c_from_referral
    from dw_dev.dev_jkizer.patient_referral pr
    left join dw_dev.dev_jkizer.patient_monthly_clinical_values pmcv
        on pr.suvida_id = pmcv.suvida_id
    where pr.is_deleted = false
    and lower(pr.email_to) = 'nutrition@suvidahealthcare.com'
    and pr.creation_date >= '2025-10-01'
),

bp_closest_to_referral as (
    select
        suvida_id,
        referral_id,
        most_recent_bp_date as bp_date_closest_to_referral,
        most_recent_bp as bp_closest_to_referral
    from bp_a1c_days
    where most_recent_bp_date is not null
    qualify row_number() over (partition by suvida_id, referral_id order by days_bp_from_referral) = 1
),

a1c_closest_to_referral as (
    select
        suvida_id,
        referral_id,
        most_recent_a1c_date as a1c_date_closest_to_referral,
        most_recent_a1c as a1c_closest_to_referral
    from bp_a1c_days
    where most_recent_a1c_date is not null
    qualify row_number() over (partition by suvida_id, referral_id order by days_a1c_from_referral) = 1
)

select
	/* Identifiers */
	pr.suvida_id,
	pr.elation_id,
	/* Patient Summary Data */
	ps.full_name,
	ps.birth_date,
	ps.phone,
	ps.phone_type,
	ps.secondary_phone,
	ps.secondary_phone_type,
	ps.elation_patient_url,
	ps.location_name,
	ps.elation_location_name,
	ps.provider_name,
	ps.elation_provider_name,
	ps.last_pcp_appt_date,
	ps.next_pcp_appt_date,
	ps.next_nutrition_appt_date,
	ps.next_careteam_appt_date,
	ps.census_rolling_12_ip_admit,
	ps.census_rolling_3_ip_admit,
	ps.is_active_assignment,
	ps.active_tag_list,
	ps.payer_name,
	ps.payer_member_id,
	ps.fap_completion_date,
	ps.is_fap_enrolled,
	ps.next_fap_form_due,
	/* Program Specific Data */
	ps.num_nutrition_visits_ytd,
	ps.first_nutrition_appt_date,
	ps.last_nutrition_appt_date,
	ps.nutrition_appt_completion_rate_rolling_12,
	ps.nutrition_appt_no_show_rate_rolling_12,
	ps.nutrition_appt_cancelled_rate_rolling_12,
	/* Referral Info */
	to_varchar(pr.referral_id) as referral_id,
	pr.referral_body_text,
	pr.email_to,
	pr.processing_status,
	pr.resolution_state,
	pr.clinical_reason,
	pr.recipient_first_name,
	pr.recipient_last_name,
	pr.recipient_org_name,
	pr.recipient_specialty,
	pr.referral_date,
	pr.document_date,
	pr.creation_date,
	pr.signed_date,
	pr.signed_datetime,
	pr.referral_icd_list,
	pr.referral_icd_description_list,
	pr.created_by_user_name,
	pr.sent_by_user_name,
	pr.signed_by_username,
	/* clinical values */
	cv.most_recent_bp_date,
	cv.most_recent_bp_systolic,
	cv.most_recent_bp_diastolic,

	cv.most_recent_a1c_date,    
	cv.most_recent_a1c,

	cv.most_recent_hdl_date,
	cv.most_recent_hdl,

	cv.most_recent_ldl_date,
	cv.most_recent_ldl,
	
	cv.most_recent_triglyceride_date,
	cv.most_recent_triglyceride,

	cv.most_recent_total_cholesterol_date,
    cv.most_recent_total_cholesterol,
	/* Closest to referral baseline values */
	bp.bp_date_closest_to_referral,
	bp.bp_closest_to_referral,
	a1c.a1c_date_closest_to_referral,
	a1c.a1c_closest_to_referral,
	/* Airtable Sync Driver Fields */
	md5(cast(coalesce(cast(pr.referral_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_unique_key,
	md5(cast(coalesce(cast(pr.signed_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.signed_by_username as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.referral_icd_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.nutrition_appt_completion_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_nutrition_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_nutrition_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.first_nutrition_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_12_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_3_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.fap_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_fap_enrolled as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_fap_form_due as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.secondary_phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_bp_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_bp_systolic as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_bp_diastolic as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_a1c_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_a1c as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_hdl_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_hdl as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_ldl_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_ldl as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_triglyceride_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_triglyceride as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_total_cholesterol_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_total_cholesterol as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bp.bp_date_closest_to_referral as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bp.bp_closest_to_referral as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(a1c.a1c_date_closest_to_referral as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(a1c.a1c_closest_to_referral as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey,
from dw_dev.dev_jkizer.patient_referral pr
left join dw_dev.dev_jkizer.patient_summary ps
	using (suvida_id)
left join clinical_lab_values cv
    using (suvida_id)
left join bp_closest_to_referral bp
    on pr.referral_id = bp.referral_id
left join a1c_closest_to_referral a1c
    on pr.referral_id = a1c.referral_id
where pr.is_deleted = false -- will not include deleted referrals
and lower(email_to) = 'nutrition@suvidahealthcare.com' -- use this to control which referrals we pick up
and creation_date >= '2025-10-01'