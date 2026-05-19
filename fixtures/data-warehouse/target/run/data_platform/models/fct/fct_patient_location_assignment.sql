-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
                
                
            
                
                
            
        
    

    

    merge into dw_dev.dev_jkizer.fct_patient_location_assignment as DBT_INTERNAL_DEST
        using dw_dev.dev_jkizer.fct_patient_location_assignment__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.report_month = DBT_INTERNAL_DEST.report_month
                ) and (
                    DBT_INTERNAL_SOURCE.suvida_id = DBT_INTERNAL_DEST.suvida_id
                ) and (
                    DBT_INTERNAL_SOURCE.location_preference_rank = DBT_INTERNAL_DEST.location_preference_rank
                )

    
    when matched then update set
        "REPORT_MONTH" = DBT_INTERNAL_SOURCE."REPORT_MONTH","SUVIDA_ID" = DBT_INTERNAL_SOURCE."SUVIDA_ID","LOCATION_NAME" = DBT_INTERNAL_SOURCE."LOCATION_NAME","WEIGHTED_ACTIVITY_SCORE" = DBT_INTERNAL_SOURCE."WEIGHTED_ACTIVITY_SCORE","APPOINTMENT_TOTAL_ACTIVITIES" = DBT_INTERNAL_SOURCE."APPOINTMENT_TOTAL_ACTIVITIES","ENCOUNTER_TOTAL_ACTIVITIES" = DBT_INTERNAL_SOURCE."ENCOUNTER_TOTAL_ACTIVITIES","TOTAL_ACTIVITIES" = DBT_INTERNAL_SOURCE."TOTAL_ACTIVITIES","LOCATION_PREFERENCE_RANK" = DBT_INTERNAL_SOURCE."LOCATION_PREFERENCE_RANK","CURRENT_LOCATION_ASSIGNMENT" = DBT_INTERNAL_SOURCE."CURRENT_LOCATION_ASSIGNMENT"
    

    when not matched then insert
        ("REPORT_MONTH", "SUVIDA_ID", "LOCATION_NAME", "WEIGHTED_ACTIVITY_SCORE", "APPOINTMENT_TOTAL_ACTIVITIES", "ENCOUNTER_TOTAL_ACTIVITIES", "TOTAL_ACTIVITIES", "LOCATION_PREFERENCE_RANK", "CURRENT_LOCATION_ASSIGNMENT")
    values
        ("REPORT_MONTH", "SUVIDA_ID", "LOCATION_NAME", "WEIGHTED_ACTIVITY_SCORE", "APPOINTMENT_TOTAL_ACTIVITIES", "ENCOUNTER_TOTAL_ACTIVITIES", "TOTAL_ACTIVITIES", "LOCATION_PREFERENCE_RANK", "CURRENT_LOCATION_ASSIGNMENT")

;
    commit;