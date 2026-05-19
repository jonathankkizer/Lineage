with clinical_values_unioned as (

    select * from  dw_dev.dev_jkizer.clinical_class_values_foodrx
        
        union all

    select * from dw_dev.dev_jkizer.clinical_class_values_mh_p

        union all

    select * from dw_dev.dev_jkizer.clinical_class_values_mh_t

        union all

    select * from dw_dev.dev_jkizer.clinical_class_values_pt_1_1

        union all

    select * from dw_dev.dev_jkizer.clinical_class_values_pt_2_1
        
        union all

    select * from dw_dev.dev_jkizer.clinical_class_values_sabor

        union all

    select * from dw_dev.dev_jkizer.clinical_class_values_steady

        union all

    select * from  dw_dev.dev_jkizer.clinical_class_values_subienestar       
)

select 
    suvida_id,
    team,
    program,
    class_name,
    appointment_date,
    value_date,
    days_between,
    value_type,
    value,
    case 
        when value_type = 'Systolic BP' and value > 140 then 1 
        when value_type = 'Hemoglobin A1c' and value > 9 then 1 
        when value_type = 'PHQ-9' and value > 9 then 1 
        when value_type = 'GAD-7' and value > 9 then 1 
        when value_type = 'Pre-TUG' and value > 14 then 1 
        when value_type = 'Post-TUG' and value > 14 then 1 
        when value_type = 'Pre-Chair-Stand' and value > 15 then 1 
        when value_type = 'Post-Chair-Stand' and value > 15 then 1 
            else 0 
                end as is_uncontrolled_value
from clinical_values_unioned