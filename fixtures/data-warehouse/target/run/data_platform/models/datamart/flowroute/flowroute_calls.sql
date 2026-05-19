-- back compat for old kwarg name
  
  begin;
    

        insert into dw_dev.dev_jkizer.flowroute_calls ("FLOWROUTE_SKEY", "DIRECTION", "START_TIME", "END_TIME", "DURATION_IN_MINUTES", "DESTINATION_PHONE_NUMBER", "DESTINATION_CONTACT_NAME", "CALLERID_PHONE_NUMBER", "CLINIC", "MARKET_NAME", "TOTAL_COST", "CALL_RESULT", "CALL_FAIL_REASON", "SUVIDA_ID")
        (
            select "FLOWROUTE_SKEY", "DIRECTION", "START_TIME", "END_TIME", "DURATION_IN_MINUTES", "DESTINATION_PHONE_NUMBER", "DESTINATION_CONTACT_NAME", "CALLERID_PHONE_NUMBER", "CLINIC", "MARKET_NAME", "TOTAL_COST", "CALL_RESULT", "CALL_FAIL_REASON", "SUVIDA_ID"
            from dw_dev.dev_jkizer.flowroute_calls__dbt_tmp
        );
    commit;