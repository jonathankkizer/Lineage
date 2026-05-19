with referrals as (                                      
      select
          suvida_id, airtable_id, recipient_specialty, referral_id, referral_date,
          referral_icd_description_list, referral_status, referral_stage,                   
          resolution_state, processing_status, care_programs_needed,
          days_referral_to_first_appt, days_since_referral                                  
      from dw_dev.dev_jkizer.patient_shared_services_nutrition_referral
                                                                                            
      union all                                       

      select
          suvida_id, airtable_id, recipient_specialty, referral_id, referral_date,
          referral_icd_description_list, referral_status, referral_stage,                   
          resolution_state, processing_status, care_programs_needed,
          days_referral_to_first_appt, days_since_referral                                  
      from dw_dev.dev_jkizer.patient_shared_services_pt_referral
                                                                                            
      union all                                       

      select
          suvida_id, airtable_id, recipient_specialty, referral_id, referral_date,
          referral_icd_description_list, referral_status, referral_stage,
          resolution_state, processing_status, care_programs_needed,
          days_referral_to_first_appt, days_since_referral
      from dw_dev.dev_jkizer.patient_shared_services_mh_referral
  ),

  shared_services as (
      select
          r.suvida_id,
          r.airtable_id,                                                                    
          ips.elation_id,
          r.recipient_specialty,                                                            
          r.referral_id,                              
          r.referral_date,
          r.referral_icd_description_list,
          r.referral_status,                                                                
          r.referral_stage,
          r.resolution_state,                                                               
          r.processing_status,                        
          r.care_programs_needed,
          r.days_referral_to_first_appt,
          r.days_since_referral,                                                            
  
          -- BP                                                                             
          pmcv.most_recent_bp_date,                   
          pmcv.most_recent_bp_systolic,
          pmcv.most_recent_bp_diastolic,                                                    
          pmcv.most_recent_bp,
          pmcv.second_most_recent_bp_date,                                                  
          pmcv.second_most_recent_bp_systolic,        
          pmcv.second_most_recent_bp_diastolic,                                             
          pmcv.second_most_recent_bp,
          pmcv.is_uncontrolled_bp,                                                          
                                                                                            
          -- HR
          pmcv.most_recent_hr_date,                                                         
          pmcv.most_recent_hr,                        
          pmcv.second_most_recent_hr_date,                                                  
          pmcv.second_most_recent_hr,
                                                                                            
          -- A1c                                                                            
          pmcv.most_recent_a1c_date,
          pmcv.most_recent_a1c,                                                             
          pmcv.second_most_recent_a1c_date,
          pmcv.second_most_recent_a1c,
          pmcv.is_uncontrolled_a1c,

          -- Triglycerides
          pmcv.most_recent_triglyceride_date,                                               
          pmcv.most_recent_triglyceride,              
          pmcv.second_most_recent_triglyceride_date,                                        
          pmcv.second_most_recent_triglyceride,     
                                                                                            
          -- LDL                                                                            
          pmcv.most_recent_ldl_date,
          pmcv.most_recent_ldl,                                                             
          pmcv.second_most_recent_ldl_date,           
          pmcv.second_most_recent_ldl      
    from referrals r                                                                      
    join dw_dev.dev_jkizer.int_patient_summary ips
        on r.suvida_id = ips.suvida_id                                                    
    left join dw_dev.dev_jkizer.patient_monthly_clinical_values pmcv       
        on r.suvida_id = pmcv.suvida_id      
        and pmcv.is_current_month = 1                                                                                     
 ),
  bp_a1c_days as (
      select
          r.suvida_id,
          r.referral_id,
          r.referral_date,                                                                                                                                                                                         
          pmcv.most_recent_bp_date,
          pmcv.most_recent_bp,                                                                                                                                                                                     
          abs(datediff(day, r.referral_date, pmcv.most_recent_bp_date))  as days_bp_from_referral,
          pmcv.most_recent_a1c_date,                                                                                                                                                                               
          pmcv.most_recent_a1c,
          abs(datediff(day, r.referral_date, pmcv.most_recent_a1c_date)) as days_a1c_from_referral                                                                                                                 
      from referrals r                                                                                                                                                                                             
      left join dw_dev.dev_jkizer.patient_monthly_clinical_values pmcv
          on r.suvida_id = pmcv.suvida_id                                                                                                                                                                          
  ),                                                                               
                                                                                                                                                                                                                   
  bp_closest_to_referral as (                                                      
      select
          suvida_id,
          referral_id,
          most_recent_bp_date as bp_date_closest_to_referral,
          most_recent_bp as bp_closest_to_referral                                                                                                                                                             
      from bp_a1c_days
      where most_recent_bp_date is not null                                                                                                                                                                        
      qualify row_number() over (partition by suvida_id, referral_id order by days_bp_from_referral) = 1    -- filter to value closest to referral date                                                                                                                                                                                                        
  ),                                                                               

  a1c_closest_to_referral as (
      select
          suvida_id,
          referral_id,                                                                                                                                                                                             
          most_recent_a1c_date as a1c_date_closest_to_referral,
          most_recent_a1c as a1c_closest_to_referral                                                                                                                                                          
      from bp_a1c_days                                                             
      where most_recent_a1c_date is not null                                                                                                                                                                       
      qualify row_number() over (partition by suvida_id, referral_id order by days_a1c_from_referral) = 1   -- filter to value closest to referral date
  )                                                                                                                                                                                                                
   
  select                                                                                                                                                                                                           
      ss.*,                                                                        
      bp.bp_date_closest_to_referral,
      bp.bp_closest_to_referral,
      a1c.a1c_date_closest_to_referral,
      a1c.a1c_closest_to_referral                                                                                                                                                                                  
  from shared_services ss
  left join bp_closest_to_referral bp                                                                                                                                                                              
      on ss.suvida_id = bp.suvida_id 
    and ss.referral_id = bp.referral_id           
  left join a1c_closest_to_referral a1c                                                                                                                                                                            
      on ss.suvida_id = a1c.suvida_id 
      and ss.referral_id = a1c.referral_id