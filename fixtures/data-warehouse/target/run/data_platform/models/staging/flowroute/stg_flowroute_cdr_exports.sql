
  create or replace   view dw_dev.dev_jkizer_staging.stg_flowroute_cdr_exports
  
  copy grants
  
  
  as (
    select 
    direction, 
    start_time, 
    end_time, 
    destination, 
    number_alias, 
    callerid, 
    total_cost, 
    destination_name, 
    callerid_country, 
    line_information, 
    result, 
    call_fail_sip_code, 
    call_fail_reason, 
    duration, 
    billed_duration, 
    rate,
    first_increment, 
    subsequent_increment, 
    cost_subtotal, 
    connect_fee, 
    usf_fee, 
    ccrf, 
    cnam_lookup_fee, 
    custom_x_tag, 
    customer_ip,
    sip_callid,
    cdr_id, 
    sip_from_tag, 
    sip_to_tag 
from source_prod.flowroute.cdr_exports
  );

