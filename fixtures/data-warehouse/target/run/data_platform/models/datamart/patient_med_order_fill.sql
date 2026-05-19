
  
    

create or replace transient table dw_dev.dev_jkizer.patient_med_order_fill
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
), provider_lookup as (
	select distinct 
		user_id, 
		user_name, 
		user_email,
	from dw_dev.dev_jkizer.dim_provider
), elation_rx as (
	select
		siw.suvida_id,
		mo.med_order_id,
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
		mo.origin,
		mo.prescribed_days_supply,
		mo.fulfillment_type,
		mo.signed_datetime,
		coalesce(deu.user_name, dp.user_name) as signed_by_username,
		coalesce(deu.user_email, dp.user_email) as signed_by_email,
		mo.creation_datetime,
		mof.med_order_fill_id,
		mof.last_fill_date,
		mof.days_supply,
		mof.medication_name,
		mof.medication_route,
		mof.medication_strength,
		mof.controlled,
		mof.quantity,
		mof.quantity_unit,
		mof.quantity_note,
		mof.medication_description,
		mof.written_date,
		mof.pharmacy_name,
		mof.pharmacy_address_line1,
		mof.pharmacy_address_line2,
		mof.pharmacy_city,
		mof.pharmacy_state,
		mof.pharmacy_zip,
		mof.pharmacy_phone_primary,
		mof.pharmacy_npi,
		mof.pharmacy_ncpdpid,
		mof.prescriber_id,
		mof.prior_auth,
		mof.active,
		mof.fuzziness,
		mof.is_deleted,
		dateadd(day, mof.days_supply + (mof.days_supply * coalesce(auth_refills, 0)), mo.med_start_date) as expected_reorder_date,
		row_number() over (partition by suvida_id, displayed_medication_name order by mof.last_fill_date) as med_order_fill_rank,
	from dw_dev.dev_jkizer_staging.stg_elation_med_order mo
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on mo.elation_id = siw.member_id
		and mo.source = siw.source
	left join dw_dev.dev_jkizer_staging.stg_elation_med_order_fill mof 
		on mo.med_order_id = mof.med_order_id
	left join dw_dev.dev_jkizer_staging.stg_elation_medication emed
		on mo.medication_id = emed.medication_id
	left join dw_dev.dev_jkizer.dim_ehr_user deu
		on mo.signed_by_user_id = deu.user_id
	left join provider_lookup dp 
		on mo.signed_by_user_id = dp.user_id
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
		WHEN erx.days_supply >= 100 then '100+ DS'
		WHEN erx.days_supply between 90 and 99 then '90-99 DS'
		WHEN erx.days_supply between 31 and 89 then '31-89 DS'
		WHEN erx.days_supply < 31 then '< 31 DS'
	END as days_supply_bucket,
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


  