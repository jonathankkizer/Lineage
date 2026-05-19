begin;
    
        delete from dw_dev.dev_jkizer.fct_patient_provider_assignment as DBT_INTERNAL_DEST
        where (report_month, suvida_id, provider_preference_rank) in (
            select distinct report_month, suvida_id, provider_preference_rank
            from dw_dev.dev_jkizer.fct_patient_provider_assignment__dbt_tmp as DBT_INTERNAL_SOURCE
        );

    

    insert into dw_dev.dev_jkizer.fct_patient_provider_assignment ("REPORT_MONTH", "SUVIDA_ID", "ASSIGNED_NPI", "WEIGHTED_ACTIVITY_SCORE", "APPOINTMENT_TOTAL_ACTIVITIES", "ENCOUNTER_TOTAL_ACTIVITIES", "TOTAL_ACTIVITIES", "PROVIDER_PREFERENCE_RANK", "CURRENT_PROVIDER_ASSIGNMENT")
    (
        select "REPORT_MONTH", "SUVIDA_ID", "ASSIGNED_NPI", "WEIGHTED_ACTIVITY_SCORE", "APPOINTMENT_TOTAL_ACTIVITIES", "ENCOUNTER_TOTAL_ACTIVITIES", "TOTAL_ACTIVITIES", "PROVIDER_PREFERENCE_RANK", "CURRENT_PROVIDER_ASSIGNMENT"
        from dw_dev.dev_jkizer.fct_patient_provider_assignment__dbt_tmp
    );
    commit;