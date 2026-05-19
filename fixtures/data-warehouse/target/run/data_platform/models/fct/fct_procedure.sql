
  
    

create or replace transient table dw_dev.dev_jkizer.fct_procedure
    copy grants
    
    
    as (with bill_item_cpts as (
	select
		*
	from dw_dev.dev_jkizer_staging.stg_elation_bill_item bi
	where bi._is_deleted_record = 0 -- only want non-deleted records
	and bi._idx = 1 -- most recent warehouse refresh date
)
select
	fe.encounter_skey,
	md5(cast(coalesce(cast(fe.encounter_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fe.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fe.bill_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fe.encounter_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fe.encounter_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fe.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fe.signed_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bi.bill_item_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bi.bill_sequence_no as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bi.cpt_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as procedure_skey,
	fe.suvida_id,
	fe.patient_id as elation_id,
	bi.cpt_code,
	fe.encounter_date,
	fe.encounter_datetime,
	bi.creation_date as cpt_date,
	bi.creation_datetime as cpt_datetime,
	fe.signed_date,
	fe.signed_datetime,
	fe.billing_date,
	fe.provider_name,
	fe.signed_by_provider_name,
	fe.service_location_name,
	fe.npi,
	fe.source,
	case when bi.cpt_code in ('G0402','G0438','G0439') then 1 else 0 end as is_awv,
	case when bi.cpt_code in ('99495','99496') then 1 else 0 end as is_tcm,
	case when bi.cpt_code in ('97802','97803','97804','S9470','S9452','G0270','G0271','G0108-8','G9873-85','G9890','G9891','G0447','G04473', '0403T','0488T') then 1 else 0 end as is_rd,
	case  When bi.cpt_code in ('93922','93931','76506','76604','76641','76642','76700','76705','76706','76770','76775','76776','76800') then 1 else 0 end as is_ultrasound,
	case  when bi.cpt_code in ('71046','73000','73010','73090','73030','73070','73080','73100','73110','70250','70260','70220','71110','73610','72082','73565','73562','73521','73522','73502','72050','72040','72080','72070','72072','72100','72114','72110','74021','74018','74019','73590','73650','73630','73660','73140','73120','73130') then 1 else 0 end as is_xray,
	case when bi.cpt_code in ('G0402','G0438','G0439','99201','99202','99203','99204','99205','99211','99212','99213','99214','99215','99495','99496') then 1 else 0 end as is_pcp,
	case  when (bi.cpt_code in ('90792','90791','99231','99214','99215','90832','90833','90834','99443')
				and fe.signed_by_user_id in ('2137931','2220240','1905133','1428801','2056688','2174678','2178729','2441031','2502271','1873124','1749352')) then 1 else 0 end as is_mh,
	case when bi.cpt_code in ('97110', '97112','97116', '97140','97150','97530','97535','97750','97761','97161','97162','97163','97164','97010','95851','95992','97542','97760','97761','97763') then 1 else 0 end as is_pt,
	case when fe.visit_note_name = 'Pharmacy Note' and fe.signed_date is not null then 1 else 0 end as is_pharmacy,
	case when fe.signed_by_user_id in ('1805598','2445515','2099789','1395340','2469608','2409488','1953236','2152788','2476765','1805301','2514117','2152765','2529520','2389318','1729344','2369175','2599065','2412303','1975912','2573018','2298405','2411407','2127861','2445612','2389453','2366356','1816191','1916505','1377722','2445370','2464830','2409684','2293547','2592412','2117485','2380599','1729348','2282549','2465566') then 1 else 0 end as is_guia,
	case when (fe.signed_by_user_id in ('1535458', '1490848', '1471168', '1453854', '1616570', '1360164', '1426797', '1364055', '1313427')
				and (fe.note_text not like '%No answer%' and fe.note_text not like '%RN Chart Review%'
				and fe.note_text not like'%High Risk Huddle Note%' and fe.note_text not like '%Case staffing%'
				and fe.note_text not like '%Notification of admission%' and fe.note_text not like '%Notification of ER Visits%'
				and fe.note_text not like '%Quality Measures submission%'))
	then 1 else 0 end as is_rn,
	case when bi.cpt_code = '1111F' then 1 else 0 end as is_postdischarge_medrec, 
	case when bi.cpt_code in ('99211', '98966') then 1 else 0 end as is_postdischarge_eval,
	case when bi.cpt_code in ('1158F') then 1 else 0 end as is_advance_directives
from dw_dev.dev_jkizer.fct_encounter fe
left join bill_item_cpts bi
	on fe.bill_id = bi.bill_id
    )
;


  