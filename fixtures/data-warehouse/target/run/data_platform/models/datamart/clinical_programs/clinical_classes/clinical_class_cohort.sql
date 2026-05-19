
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_class_cohort
    copy grants
    
    
    as (with classes_unioned as (

        select * from dw_dev.dev_jkizer.clinical_class_fam

            union all 
        
        select * from dw_dev.dev_jkizer.clinical_class_steady

            union all
        
        select * from dw_dev.dev_jkizer.clinical_class_subienestar

            union all
        
        select * from dw_dev.dev_jkizer.clinical_class_sabor_vida

            union all 

        select * from dw_dev.dev_jkizer.clinical_class_foodrx

            union all
        
        select * from dw_dev.dev_jkizer.clinical_class_mh_p

            union all 

        select * from dw_dev.dev_jkizer.clinical_class_mh_t

            union all
        
        select * from dw_dev.dev_jkizer.clinical_class_pt_one_one

            union all
        
        select * from dw_dev.dev_jkizer.clinical_class_pt_two_one

            union all
        
        select * from dw_dev.dev_jkizer.clinical_class_mh_toc
)

select
    suvida_id,
    team,
    program,
    class_name,
    appointment_type_category,
    cohort,
    cohort_number,
    apt_number_in_cohort,
    graduation_status,
    location_name,
    appointment_date,
    previous_apt_date,
    days_since_last_apt,
--    appointment_description,
--    appointment_status,
    apts_attended_in_cohort,
    tag_value,
    tag_date,
from classes_unioned
    )
;


  