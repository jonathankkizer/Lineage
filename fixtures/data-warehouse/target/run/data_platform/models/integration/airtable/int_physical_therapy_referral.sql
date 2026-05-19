
  
    

create or replace transient table dw_dev.dev_jkizer.int_physical_therapy_referral
    copy grants
    
    
    as (

with clinical_values as (
	select
		suvida_id,
		/* TUG */
		max(iff(history_type = 'TUG' and patient_history_index = 1, history_value_numeric, null)) as most_recent_tug_value,
		max(iff(history_type = 'TUG' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_tug_date,
		max(iff(history_type = 'TUG' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_tug_value,
		max(iff(history_type = 'TUG' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_tug_date,
		/* Pre-TUG */
		max(iff(history_type = 'Pre-TUG' and patient_history_index = 1, history_value_numeric, null)) as most_recent_pre_tug_value,
		max(iff(history_type = 'Pre-TUG' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_pre_tug_date,
		max(iff(history_type = 'Pre-TUG' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_pre_tug_value,
		max(iff(history_type = 'Pre-TUG' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_pre_tug_date,
		/* Pre-Chair-Stand */
		max(iff(history_type = 'Pre-Chair-Stand' and patient_history_index = 1, history_value_numeric, null)) as most_recent_pre_chair_stand_value,
		max(iff(history_type = 'Pre-Chair-Stand' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_pre_chair_stand_date,
		max(iff(history_type = 'Pre-Chair-Stand' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_pre_chair_stand_value,
		max(iff(history_type = 'Pre-Chair-Stand' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_pre_chair_stand_date,
		/* Post-Chair-Stand */
		max(iff(history_type = 'Post-Chair-Stand' and patient_history_index = 1, history_value_numeric, null)) as most_recent_post_chair_stand_value,
		max(iff(history_type = 'Post-Chair-Stand' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_post_chair_stand_date,
		max(iff(history_type = 'Post-Chair-Stand' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_post_chair_stand_value,
		max(iff(history_type = 'Post-Chair-Stand' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_post_chair_stand_date,
	from dw_dev.dev_jkizer.fct_patient_history
	where history_type in ('TUG', 'Pre-TUG', 'Pre-Chair-Stand', 'Post-Chair-Stand') and history_value_numeric is not null
	group by all
),

pt_individual_aggregates as (
	select
		suvida_id,
		min(case when appointment_date >= current_date() then appointment_date end) as next_pt_individual_appt_date,
		min(case when appointment_completed_ind = 1 then appointment_date end) as first_pt_individual_appt_date,
		max(case when appointment_completed_ind = 1 then appointment_date end) as last_pt_individual_appt_date
	from dw_dev.dev_jkizer.fct_appointment
	where is_pt_appt = true
		and is_class = false
	group by 1
),

-- One-time PT Airtable migration snapshot: tags active as of 2026-04-19.
-- Going forward, new PT patients flow in via referrals only; do not change this date.
pt_tags as (
	select
		suvida_id,
		patient_tag_skey,
		tag_value,
		creation_datetime as tag_creation_datetime,
		deletion_datetime as tag_deletion_datetime,
		tag_created_by_user_id,
	from dw_dev.dev_jkizer.fct_patient_tag
	where tag_value in ('PT- 1x/wk', 'PT- 2x/wk', 'PT- 2:1', 'PT- 1:1')
		and creation_datetime < '2026-04-19'
		and (deletion_datetime is null or deletion_datetime >= '2026-04-19')
),

referral_rows as (
	select
		/* Source */
		'Referral'::varchar as source_type,
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
		pia.next_pt_individual_appt_date as next_pt_appt_date,
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
		ps.rolling_12_fall_er_visits,
		ps.rolling_12_fall_ip_visits,
		/* Program Specific Data */
		ps.num_pt_visits_ytd,
		pia.first_pt_individual_appt_date as first_pt_appt_date,
		pia.last_pt_individual_appt_date as last_pt_appt_date,
		ps.pt_appt_completion_rate_rolling_12,
		ps.pt_appt_no_show_rate_rolling_12,
		ps.pt_appt_cancelled_rate_rolling_12,
		ps.sdoh_form_due_ind,
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
		/* Tag Info (null for referral rows) */
		null::varchar as tag_value,
		null::timestamp as tag_creation_datetime,
		null::timestamp as tag_deletion_datetime,
		null::varchar as tag_created_by_user_id,
		/* clinical values */
		cv.most_recent_tug_value,
		cv.most_recent_tug_date,
		cv.second_most_recent_tug_value,
		cv.second_most_recent_tug_date,
		cv.most_recent_pre_tug_value,
		cv.most_recent_pre_tug_date,
		cv.second_most_recent_pre_tug_value,
		cv.second_most_recent_pre_tug_date,
		cv.most_recent_pre_chair_stand_value,
		cv.most_recent_pre_chair_stand_date,
		cv.second_most_recent_pre_chair_stand_value,
		cv.second_most_recent_pre_chair_stand_date,
		cv.most_recent_post_chair_stand_value,
		cv.most_recent_post_chair_stand_date,
		cv.second_most_recent_post_chair_stand_value,
		cv.second_most_recent_post_chair_stand_date,
		/* Airtable Sync Driver Fields -- keep identical to original so existing Airtable records aren't recreated */
		md5(cast(coalesce(cast(referral_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_unique_key,
		md5(cast(coalesce(cast(pr.signed_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.signed_by_username as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.referral_icd_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.pt_appt_completion_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pia.next_pt_individual_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pia.first_pt_individual_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pia.last_pt_individual_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_12_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_3_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.fap_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_fap_enrolled as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_fap_form_due as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.secondary_phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.sdoh_form_due_ind as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_post_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_post_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_post_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_post_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey,
	from dw_dev.dev_jkizer.patient_referral pr
	left join dw_dev.dev_jkizer.patient_summary ps
		using (suvida_id)
	left join clinical_values cv
		using (suvida_id)
	left join pt_individual_aggregates pia
		using (suvida_id)
	where pr.is_deleted = false -- will not include deleted referrals
	and (
		(
			recipient_org_name = 'Physical Therapy (Suvida)'
			and creation_date >= '2026-03-01'
		)
		or pr.referral_id in (
			1153166824898592,
			1180286874615840,
			1192753072898080,
			1204347953545248,
			1143947591221280,
			1179124956659744,
			1151554252898336,
			1160178329059360,
			1115906155872288,
			1161445243420704,
			1135839052759072,
			1178584015896608,
			1201110747512864,
			1198994604884000,
			1182953113583648,
			1132695236247584,
			1193530187317280,
			1140101252317216,
			1191332485988384,
			1156596584677408,
			1126103109795872,
			1134872739971104,
			919677764239392,
			1165090526658592,
			1198280885731360,
			1205200520937504,
			1200843871289376,
			1118788181295136,
			1132629047246880,
			1153848995545120,
			1150850539061280,
			1154667359698976,
			1176651029151776,
			1180639541329952,
			1171428804984864,
			1184884428439584,
			1178118859718688,
			1183756212043808,
			1183043543236640,
			1160813235863584,
			1247624479440928,
			1199068300574752,
			1189432011194400,
			1125269571829792,
			1168273353605152,
			1171527261880352,
			1136479331287072,
			1202568728608800,
			1162315047829536,
			1218682052018208,
			1198782775099424,
			1205336268931104,
			1121014779150368,
			1192534637936672,
			1145985362624544,
			1151755143610400,
			1184139981226016,
			1191412901675040,
			1198885170708512,
			1159217884037152,
			1195673950027808,
			1177151603605536,
			1141484068995104,
			1193450053173280,
			1186161240440864,
			1200007805927456,
			1172862009868320,
			1198693804671008,
			1192532972863520,
			1201276567486496,
			1164749349519392,
			1170568339324960,
			1169116847734816,
			1188321001078816,
			1182608957702176,
			1202449513054240,
			1133371980840992,
			1167369205121056,
			1204568742494240,
			1198577285726240,
			1153875691503648,
			1199800220385312,
			1161803831115808,
			1176065019215904,
			1170583738515488,
			1126017459224608,
			1140103095910432,
			1147302597034016,
			1142376140111904,
			1181536977813536,
			1196404831092768,
			1174787247898656,
			1161699217047584,
			1140032523141152,
			1206665355329568,
			1160242482774048,
			1160490234544160,
			1162774840410144,
			1195315497533472,
			1202181602344992,
			1141799380910112,
			1196526875836448,
			1168178035818528,
			1171866837254176,
			1198070966714400,
			1205289502769184,
			1199796425261088,
			1159074668216352,
			1147404045451296,
			1150106029391904,
			1195360903036960,
			1202239919226912,
			1164449434042400,
			1196918359261216,
			1135887059583008,
			1199792612376608,
			1204823403986976,
			1183335171817504,
			1110217354510368,
			1126988393742368,
			1197955376480288,
			1195518393712672,
			1114887654866976,
			1212823494787104,
			1138739090948128,
			1195332887707680,
			1198006877093920,
			1183910455148576,
			1158114806661152,
			1170383814787104
		)
	)
),

tag_rows as (
	select
		/* Source */
		'Elation Tag'::varchar as source_type,
		/* Identifiers */
		t.suvida_id,
		ps.elation_id,
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
		pia.next_pt_individual_appt_date as next_pt_appt_date,
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
		ps.rolling_12_fall_er_visits,
		ps.rolling_12_fall_ip_visits,
		/* Program Specific Data */
		ps.num_pt_visits_ytd,
		pia.first_pt_individual_appt_date as first_pt_appt_date,
		pia.last_pt_individual_appt_date as last_pt_appt_date,
		ps.pt_appt_completion_rate_rolling_12,
		ps.pt_appt_no_show_rate_rolling_12,
		ps.pt_appt_cancelled_rate_rolling_12,
		ps.sdoh_form_due_ind,
		/* Referral Info (null for tag rows) */
		null::varchar as referral_id,
		null::varchar as referral_body_text,
		null::varchar as email_to,
		null::varchar as processing_status,
		null::varchar as resolution_state,
		null::varchar as clinical_reason,
		null::varchar as recipient_first_name,
		null::varchar as recipient_last_name,
		null::varchar as recipient_org_name,
		null::varchar as recipient_specialty,
		null::date as referral_date,
		null::date as document_date,
		null::date as creation_date,
		null::date as signed_date,
		null::timestamp as signed_datetime,
		null::varchar as referral_icd_list,
		null::varchar as referral_icd_description_list,
		null::varchar as created_by_user_name,
		null::varchar as sent_by_user_name,
		null::varchar as signed_by_username,
		/* Tag Info */
		t.tag_value,
		t.tag_creation_datetime,
		t.tag_deletion_datetime,
		t.tag_created_by_user_id,
		/* clinical values */
		cv.most_recent_tug_value,
		cv.most_recent_tug_date,
		cv.second_most_recent_tug_value,
		cv.second_most_recent_tug_date,
		cv.most_recent_pre_tug_value,
		cv.most_recent_pre_tug_date,
		cv.second_most_recent_pre_tug_value,
		cv.second_most_recent_pre_tug_date,
		cv.most_recent_pre_chair_stand_value,
		cv.most_recent_pre_chair_stand_date,
		cv.second_most_recent_pre_chair_stand_value,
		cv.second_most_recent_pre_chair_stand_date,
		cv.most_recent_post_chair_stand_value,
		cv.most_recent_post_chair_stand_date,
		cv.second_most_recent_post_chair_stand_value,
		cv.second_most_recent_post_chair_stand_date,
		/* Airtable Sync Driver Fields */
		md5(cast(coalesce(cast('Elation Tag' as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.patient_tag_skey as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_unique_key,
		md5(cast(coalesce(cast('Elation Tag' as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(null as date) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(null as varchar) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(null as varchar) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.pt_appt_completion_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pia.next_pt_individual_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pia.first_pt_individual_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pia.last_pt_individual_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_12_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_3_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.fap_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_fap_enrolled as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_fap_form_due as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.secondary_phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.sdoh_form_due_ind as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_creation_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_deletion_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_created_by_user_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_tug_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_tug_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_pre_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_pre_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_post_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_post_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_post_chair_stand_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_post_chair_stand_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey,
	from pt_tags t
	left join dw_dev.dev_jkizer.patient_summary ps
		using (suvida_id)
	left join clinical_values cv
		using (suvida_id)
	left join pt_individual_aggregates pia
		using (suvida_id)
)

select * from referral_rows
union all
select * from tag_rows
    )
;


  