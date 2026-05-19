
  
    

create or replace transient table dw_dev.dev_jkizer.patient_med_order_discontinued
    copy grants
    
    
    as (select
	siw.suvida_id,
	mo.med_order_id,
	mo.med_start_date,
	mo.displayed_medication_name,
	mo.ndc,
	mo.med_type,
	mo.medication_type,
	mo.med_route,
	mo.strength,
	mo.directions,
	mo.form,
	mo.auth_refills,
	mo.origin,
	mo.fulfillment_type,
	mo.signed_datetime,
	mo.creation_datetime,
	mo.deletion_date,
	mo.deleted_by_user_id,
    disc.discontinue_date,
    disc.reason as discontinue_reason,
	mof.last_fill_date,
	mof.days_supply,
	mof.pharmacy_name,
	mof.pharmacy_address_line1,
	mof.pharmacy_address_line2,
	mof.pharmacy_city,
	mof.pharmacy_state,
	mof.pharmacy_zip,
	mof.pharmacy_phone_primary,
	mof.pharmacy_npi
from dw_dev.dev_jkizer_staging.stg_elation_med_order mo
inner join dw_dev.dev_jkizer.suvida_id_walk siw
	on mo.elation_id = siw.member_id
	and mo.source = siw.source
left join dw_dev.dev_jkizer_staging.stg_elation_med_order_fill mof 
	on mo.med_order_id = mof.med_order_id
left join dw_dev.dev_jkizer_staging.stg_elation_discontinue_med_order disc 
    on disc.med_order_id = mo.med_order_id
where disc.discontinue_date is not null or mo.deletion_date is not null
    )
;


  