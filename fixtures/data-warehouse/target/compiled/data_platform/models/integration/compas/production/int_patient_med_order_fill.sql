select
    mo.suvida_id,
    mo.elation_id,
    mo.med_order_id,
    mo.med_order_thread_id,
    mof.med_order_fill_id,
    mof.last_fill_date,
    mof.days_supply,
    mof.quantity,
    mof.quantity_unit,
    mof.pharmacy_name,
    mof.pharmacy_address_line1,
    mof.pharmacy_address_line2,
    mof.pharmacy_city,
    mof.pharmacy_state,
    mof.pharmacy_zip,
    mof.pharmacy_phone_primary,
    mof.pharmacy_npi,    
	CASE 
		WHEN mof.days_supply >= 100 then '100+ DS'
		WHEN mof.days_supply between 90 and 99 then '90-99 DS'
		WHEN mof.days_supply between 31 and 89 then '31-89 DS'
		WHEN mof.days_supply < 31 then '< 31 DS'
	END as days_supply_bucket,
    dateadd(day, mof.days_supply + (mof.days_supply * coalesce(mo.auth_refills, 0)), mo.med_start_date) as expected_reorder_date,
    row_number() over (partition by mo.med_order_thread_id, mo.med_order_id order by mof.last_fill_date desc) as med_order_fill_rank,
from dw_dev.dev_jkizer_staging.stg_elation_med_order_fill mof
inner join dw_dev.dev_jkizer.int_patient_med_order mo 
    on mo.med_order_id = mof.med_order_id