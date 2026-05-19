begin;
    
        delete from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental as DBT_INTERNAL_DEST
        where (suvida_id, snapshot_date) in (
            select distinct suvida_id, snapshot_date
            from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental__dbt_tmp as DBT_INTERNAL_SOURCE
        );

    

    insert into dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental ("SUVIDA_ID", "ELATION_ID", "ELATION_PATIENT_URL", "FULL_NAME", "PHONE", "NUM_PCP_VISITS_YTD", "IS_AWV_COMPLETE_YTD", "LAST_PCP_APPT_DATE", "PREFERRED_LANGUAGE", "LOCATION_NAME", "PROVIDER_NAME", "EMR_CLAIMS_BLENDED_RISK_SCORE_ADJ_ROLLING", "OUTSTANDING_V28_COMMUNITY_RAF", "RECENT_COME_BACK_CARE_NOTE_TEXT", "ELIGIBILITY_START_MONTH", "CUMULATIVE_PCP_VISITS", "HIGH_RISK_PATIENT", "DUAL_STATUS", "PRIORITY", "DAYS_SINCE_LAST_PCP_VISIT", "CATEGORY", "DATE_SORT", "SNAPSHOT_DATE", "INTEGRATION_SKEY")
    (
        select "SUVIDA_ID", "ELATION_ID", "ELATION_PATIENT_URL", "FULL_NAME", "PHONE", "NUM_PCP_VISITS_YTD", "IS_AWV_COMPLETE_YTD", "LAST_PCP_APPT_DATE", "PREFERRED_LANGUAGE", "LOCATION_NAME", "PROVIDER_NAME", "EMR_CLAIMS_BLENDED_RISK_SCORE_ADJ_ROLLING", "OUTSTANDING_V28_COMMUNITY_RAF", "RECENT_COME_BACK_CARE_NOTE_TEXT", "ELIGIBILITY_START_MONTH", "CUMULATIVE_PCP_VISITS", "HIGH_RISK_PATIENT", "DUAL_STATUS", "PRIORITY", "DAYS_SINCE_LAST_PCP_VISIT", "CATEGORY", "DATE_SORT", "SNAPSHOT_DATE", "INTEGRATION_SKEY"
        from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental__dbt_tmp
    );
    commit;