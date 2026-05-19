-- Airtable base: PharmD Operations

with problem_list_agg as (
	select
		suvida_id,
		listagg(distinct problem_description, ' | ') within group (order by problem_description) as dx_problem_list
	from dw_dev.dev_jkizer.patient_problem_list
	where is_most_recent_problem = true
	group by suvida_id
)
select
	/* skeys */
	md5(cast(coalesce(cast(pr.referral_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as referral_skey,
	md5(cast(coalesce(cast(pr.referral_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.signed_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.pharmacy_appt_completion_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.pharmacy_appt_no_show_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.pharmacy_appt_cancelled_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.birth_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pla.dx_problem_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.payer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.num_pcp_visits_ytd as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.num_pharmacy_visits_ytd as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pharmacy_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pharmacy_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.most_recent_a1c as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.most_recent_a1c_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.second_most_recent_a1c as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.second_most_recent_a1c_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.most_recent_bp as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.most_recent_bp_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.second_most_recent_bp as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.second_most_recent_bp_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.most_recent_hr as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.most_recent_hr_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.second_most_recent_hr as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmcv.second_most_recent_hr_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.cbp_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.cbp_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.hbd_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.hbd_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.supd_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.supd_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.spc_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.spc_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.mah_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.mah_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.mad_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.mad_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.mac_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.mac_qe_stage as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.poly_ach_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmq.cob_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(1 as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey,
	/* info related to specific instance of referral */
	pr.signed_date as referral_date,
	pr.signed_by_username as signer_of_referral,
	pr.clinical_reason as reason_for_referral,
	pr.referral_icd_description_list as dx_within_referral,
	/* patient information; should always be current information */
	ps.location_name,
	ps.provider_name,
	ps.pharmacy_appt_completion_rate_rolling_12,
	ps.pharmacy_appt_no_show_rate_rolling_12,
	ps.pharmacy_appt_cancelled_rate_rolling_12,
	ps.suvida_id,
	ps.last_name,
	ps.first_name,
	ps.birth_date,
	ps.active_tag_list,
	pla.dx_problem_list,
	ps.phone as primary_phone_number,
	ps.secondary_phone as secondary_phone_number,
	ps.payer_name,
	ps.elation_patient_url,
	ps.next_pcp_appt_date,
	ps.last_pcp_appt_date,
	ps.num_pcp_visits_ytd,
	ps.num_pharmacy_visits_ytd,
	ps.last_pharmacy_appt_date,
	ps.next_pharmacy_appt_date,
	ps.high_risk_patient,
	/* labs */
	pmcv.most_recent_a1c as labs_most_recent_a1c_value,
	pmcv.most_recent_a1c_date as labs_most_recent_a1c_date,
	pmcv.second_most_recent_a1c as labs_2nd_most_recent_a1c_value,
	pmcv.second_most_recent_a1c_date as labs_2nd_most_recent_a1c_date,
	/* Vitals */
	split_part(pmcv.most_recent_bp, '/', 1) as vitals_most_recent_systolic_bp_value,
    split_part(pmcv.most_recent_bp, '/', 2) as vitals_most_recent_diastolic_bp_value,
    pmcv.most_recent_bp_date as vitals_most_recent_bp_date,
    split_part(pmcv.second_most_recent_bp, '/', 1) as vitals_2nd_most_recent_systolic_bp_value,
    split_part(pmcv.second_most_recent_bp, '/', 2) as vitals_2nd_most_recent_diastolic_bp_value,
	pmcv.second_most_recent_bp_date as vitals_2nd_most_recent_bp_date,
	pmcv.most_recent_hr as vitals_most_recent_hr_value,
	pmcv.most_recent_hr_date as vitals_most_recent_hr_date,
	pmcv.second_most_recent_hr as vitals_2nd_most_recent_hr_value,
	pmcv.second_most_recent_hr_date as vitals_2nd_most_recent_hr_date,
	/* quality measure data */
	pmq.cbp_status,
	pmq.cbp_qe_stage,
	pmq.hbd_status as a1c_status,
	pmq.hbd_qe_stage as a1c_qe_stage,
	pmq.supd_status,
	pmq.supd_qe_stage,
	pmq.spc_status,
	pmq.spc_qe_stage,
	pmq.mah_status,
	pmq.mah_qe_stage,
	pmq.mad_status,
	pmq.mad_qe_stage,
	pmq.mac_status,
	pmq.mac_qe_stage,
	pmq.poly_ach_status,
	null as poly_ach_qe_stage,
	pmq.cob_status,
	null as cob_qe_stage
from dw_dev.dev_jkizer.patient_referral pr
left join dw_dev.dev_jkizer.patient_summary ps
	on pr.suvida_id = ps.suvida_id
left join dw_dev.dev_jkizer.patient_monthly_quality pmq
	on pr.suvida_id = pmq.suvida_id
	and pmq.is_current_month = true
left join dw_dev.dev_jkizer.patient_monthly_clinical_values pmcv
	on pr.suvida_id = pmcv.suvida_id
	and pmcv.is_current_month = true
left join problem_list_agg pla
	on pr.suvida_id = pla.suvida_id
where recipient_org_name = 'Pharmacy (Suvida)'