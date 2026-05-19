
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_med_order_uat
    copy grants
    
    
    as (with elation_code_rx_join as (
	select
		mrx.medication_id,
		mrx.cui,
		rxnorm.*,
	from dw_dev.dev_jkizer_staging.stg_elation_medication_rxnorm mrx 
	inner join dw_dev.dev_jkizer_staging.stg_atc_codes_to_rxnorm_products rxnorm 
		on mrx.cui = rxnorm.rxcui
	qualify row_number() over (partition by mrx.medication_id order by mrx.cui desc) = 1
), user_lookup as (
	select distinct 
		user_id,
        user_staff_id,
        physician_id,
		user_name, 
		user_email,
	from dw_dev.dev_jkizer.ehr_user
), elation_rx as (
	select
		ps.suvida_id,
        mo.elation_id,
		mo.med_order_id,
        mo.med_order_thread_id,
		mo.med_start_date,
		mo.medication_id,
		mo.displayed_medication_name,
		mo.ndc,
		iff(left(replace(mo.ndc, '-', ''), 4) = '0000', substring(replace(mo.ndc, '-', ''), 3), replace(mo.ndc, '-', '')) as ndc_raw,
		mo.med_type,
		mo.medication_type,
		mo.med_route,
		mo.strength,
		mo.directions,
		mo.form,
		mo.auth_refills,
        mo.documenting_personnel_id,
        dpi.user_name as documented_by_username,
        dpi.user_email as documented_by_email,
		mo.origin,
		mo.prescribed_days_supply,
		mo.fulfillment_type,
		mo.signed_datetime,
        mo.signed_by_user_id,
		coalesce(deu.user_name, dp.user_name) as signed_by_username,
		coalesce(deu.user_email, dp.user_email) as signed_by_email,
		mo.creation_datetime,
        mo.created_by_user_id,
        cb.user_name as created_by_username,
        cb.user_email as created_by_email
	from dw_dev.dev_jkizer_staging.stg_elation_med_order mo
	inner join dw_dev.dev_jkizer.int_patient_summary_uat ps
		on mo.elation_id = ps.elation_id
	left join dw_dev.dev_jkizer_staging.stg_elation_medication emed
		on mo.medication_id = emed.medication_id
	left join user_lookup deu
		on mo.signed_by_user_id = deu.user_id
	left join user_lookup dp 
		on mo.signed_by_user_id = dp.user_id
    left join user_lookup dpi
        on mo.documenting_personnel_id = dpi.user_staff_id or
           mo.documenting_personnel_id = dpi.physician_id    
    left join user_lookup cb
        on mo.created_by_user_id = cb.user_id
	where mo.deletion_datetime is null
)
select
	erx.*,
	rxn.rxcui,
	rxn.rxnorm_description,
	rxn.atc_1_code,
	rxn.atc_2_code,
	rxn.atc_3_code,
	rxn.atc_4_code,
	rxn.atc_1_name,
	rxn.atc_2_name,
	rxn.atc_3_name,
	rxn.atc_4_name,    
	CASE 
		WHEN erx.prescribed_days_supply >= 100 then '100+ DS'
		WHEN erx.prescribed_days_supply between 90 and 99 then '90-99 DS'
		WHEN erx.prescribed_days_supply between 31 and 89 then '31-89 DS'
		WHEN erx.prescribed_days_supply < 31 then '< 31 DS'
	END as prescribed_days_supply_bucket
from elation_rx erx 
inner join elation_code_rx_join rxn 
	on erx.medication_id = rxn.medication_id
    )
;


  