
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_class_values_pt_2_1
    copy grants
    
    
    as (


with clinical_values_all as (
    select
        ccc.suvida_id,
        'Physical Therapy' as team,
        'PT-2:1' as program,
        '2:1' as class_name,
        ccc.appointment_date,
        value_date,
        abs(datediff(day, value_date, appointment_date)) as days_between,
        value_type,
        value
    from dw_dev.dev_jkizer.clinical_class_pt_two_one ccc
    left join dw_dev.dev_jkizer.clinical_values cv
        on ccc.suvida_id = cv.suvida_id
        --and date_trunc(month, cv.value_date) = date_trunc(month, ccc.appointment_date)    -- remove if testing works
        and ((value_type in ('Pre-TUG', 'Pre-Chair-Stand')
            and cv.value_date <= ccc.appointment_date
            and datediff(day, cv.value_date, ccc.appointment_date) <= 42)
        or (value_type in ('Post-TUG', 'Post-Chair-Stand')
            and cv.value_date >= ccc.appointment_date
            and datediff(day, ccc.appointment_date, cv.value_date) <= 42))
    qualify row_number() over(partition by ccc.suvida_id, value_date, value_type
        order by days_between) = 1  -- prevent multiple appointments from attaching to 1 value of a value type
)
    select
        ccc.suvida_id, 
        'Physical Therapy' as team,
        'PT-2:1' as program,
        '2:1' as class_name,
        ccc.appointment_date,
        cva.value_date,
        cva.days_between,
        cva.value_type,
        cva.value
    from dw_dev.dev_jkizer.clinical_class_pt_two_one ccc
    left join clinical_values_all  cva
        on ccc.suvida_id = cva.suvida_id
        and ccc.appointment_date = cva.appointment_date
    qualify row_number() over(partition by ccc.suvida_id, ccc.appointment_date, cva.value_type 
        order by cva.days_between) = 1       -- prevent more than 1 value of a value type from attaching itself to 1 appointment date

  
    )
;


  