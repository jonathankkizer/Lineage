
  
    

create or replace transient table tuva_dev.dev_jkizer_input_layer.pharmacy_claim
    copy grants
    
    
    as (select 
	claim_id,
	claim_line_number,
	siw.suvida_id as person_id,
	dpc.member_id,
	data_source as payer,
	data_source as plan,
	prescribing_provider_npi,
	dispensing_provider_npi,
	dispensing_date::date as dispensing_date,
	ndc_code,
	quantity,
	days_supply,
	refills,
	paid_date::date as paid_date,
	paid_amount,
	allowed_amount,
	null as charge_amount,
	null as coinsurance_amount,
	null as copayment_amount,
	null as deductible_amount,
	data_source as data_source,
	null as in_network_flag,
	null as file_name,
	null as file_date,
	null as ingest_datetime,
from dw_dev.dev_jkizer_staging.stg_devoted_pharmacy_claim dpc
inner join dw_dev.dev_jkizer.suvida_id_walk siw 
	on dpc.member_id = siw.member_id
	and dpc.data_source = siw.source
where dpc._rn = 1
and claim_line_number is not null
qualify row_number() over (partition by claim_id, claim_line_number, data_source order by data_source) = 1
    )
;


  