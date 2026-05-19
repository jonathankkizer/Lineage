with source as (
	select
		sharepoint_item_id,
		sharepoint_list_name,
		parse_json(cast(record_data as varchar)) as record_data,
		try_to_timestamp(snapshot_datetime) as snapshot_at,
		try_to_timestamp(last_modified_datetime) as last_modified_at,
		try_to_timestamp(ingestion_datetime) as ingested_at
	from source_prod.sharepoint_list.modification_history
	where sharepoint_list_name = 'Patient Outreach Worklist'
		and sharepoint_item_id is not null
)

select
	-- source metadata
	sharepoint_item_id,
	sharepoint_list_name,
	cast(snapshot_at as date) as snapshot_date,

	-- patient identifiers
	to_varchar(cast(record_data:SuvidaID as number(38, 0))) as suvida_id,
	to_varchar(cast(record_data:ElationID as number(38, 0))) as elation_id,
	cast(record_data:ElationURL as varchar) as elation_url,

	-- patient demographics
	cast(record_data:Fullname as varchar) as full_name,
	cast(record_data:Phone as varchar) as phone,
	cast(record_data:Preferredlanguage as varchar) as preferred_language,
	cast(record_data:DualStatus as varchar) as dual_status,

	-- care team & location
	cast(record_data:LocationName as varchar) as location_name,
	cast(record_data:Providername as varchar) as provider_name,

	-- outreach classification
	cast(record_data:Category as varchar) as category,
	cast(record_data:PRIORITY as varchar) as priority,

	-- outreach outcome
	cast(record_data:Outcome as varchar) as outcome,

	-- outreach attempts
	try_to_date(cast(record_data:CC_x0020_Attempt_x0020_1_x0020__0 as varchar)) as attempt_1_date,
	cast(record_data:CC_x0020_Attempt_x0020_1_x0020__1 as varchar) as attempt_1_result,
	cast(record_data:CC_x0020_Attempt_x0020_1_x0020__LookupId as integer) as attempt_1_who_id,
	try_to_date(cast(record_data:CC_x0020_Attempt_x0020_2_x0020__0 as varchar)) as attempt_2_date,
	cast(record_data:CC_x0020_Attempt_x0020_2_x0020__1 as varchar) as attempt_2_result,
	cast(record_data:CC_x0020_Attempt_x0020_2_x0020__LookupId as integer) as attempt_2_who_id,
	try_to_date(cast(record_data:CC_x0020_Attempt_x0020_3_x0020__0 as varchar)) as attempt_3_date,
	cast(record_data:CC_x0020_Attempt_x0020_3_x0020__1 as varchar) as attempt_3_result,
	cast(record_data:CC_x0020_Attempt_x0020_3_x0020__LookupId as integer) as attempt_3_who_id,
	try_to_date(cast(record_data:CC_x0020_Attempt_x0020_4_x0020__0 as varchar)) as attempt_4_date,
	cast(record_data:CC_x0020_Attempt_x0020_4_x0020__1 as varchar) as attempt_4_result,
	cast(record_data:CC_x0020_Attempt_x0020_4_x0020__LookupId as integer) as attempt_4_who_id,

	-- visit & engagement metrics
	cast(record_data['_x0023_ofPCPVisitsytd'] as integer) as num_pcp_visits_ytd,
	iff(cast(record_data:IsAWVCompleteYTD as integer) = 1, true, false) as is_awv_complete_ytd,
	cast(record_data:DaysSinceLastPCPVisit as integer) as days_since_last_pcp_visit,
	cast(record_data:CumulativePCPVisits as integer) as cumulative_pcp_visits,
	cast(try_to_timestamp(cast(record_data:LastPCPAppt as varchar)) as date) as last_pcp_appt_date,
	cast(try_to_timestamp(cast(record_data:EligibilityStartMonth as varchar)) as date) as eligibility_start_month,

	-- risk scores
	cast(record_data:RollingRiskScore as float) as rolling_risk_score,
	cast(record_data:OutstandingRiskScore as float) as outstanding_risk_score,
	iff(cast(record_data['HighRiskPatient_x003f_'] as integer) = 1, true, false) as high_risk_patient,

	-- record audit
	try_to_timestamp(cast(record_data:Created as varchar)) as record_created_at,
	last_modified_at,
	snapshot_at,
	ingested_at,
	row_number() over (
		partition by sharepoint_item_id, snapshot_date
		order by snapshot_at desc
	) as _idx
from source