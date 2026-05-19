begin;
    
        delete from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental as DBT_INTERNAL_DEST
        where (suvida_id, snapshot_date) in (
            select distinct suvida_id, snapshot_date
            from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental__dbt_tmp as DBT_INTERNAL_SOURCE
        );

    

    insert into dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental ("SUVIDA_ID", "FULL_NAME", "FIRST_NAME", "LAST_NAME", "BIRTH_DATE", "ELATION_PATIENT_URL", "LOCATION_NAME", "PAYER_NAME", "ELATION_INSURANCE_NAME", "ELATION_INSURANCE_PLAN", "ELATION_INSURANCE_MEMBER_ID", "ELIGIBILITY_START_MONTH", "LAST_PCP_APPT_DATE", "NEXT_PCP_APPT_DATE", "CUMULATIVE_PCP_VISITS", "NUM_PCP_VISITS_YTD_GROUP", "HIGH_RISK_PATIENT", "SNAPSHOT_DATE", "INTEGRATION_SKEY")
    (
        select "SUVIDA_ID", "FULL_NAME", "FIRST_NAME", "LAST_NAME", "BIRTH_DATE", "ELATION_PATIENT_URL", "LOCATION_NAME", "PAYER_NAME", "ELATION_INSURANCE_NAME", "ELATION_INSURANCE_PLAN", "ELATION_INSURANCE_MEMBER_ID", "ELIGIBILITY_START_MONTH", "LAST_PCP_APPT_DATE", "NEXT_PCP_APPT_DATE", "CUMULATIVE_PCP_VISITS", "NUM_PCP_VISITS_YTD_GROUP", "HIGH_RISK_PATIENT", "SNAPSHOT_DATE", "INTEGRATION_SKEY"
        from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental__dbt_tmp
    );
    commit;