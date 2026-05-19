with combined_data as (
    select 
        med.med_order_id as order_id, 
        med.elation_id, 
        med.medication_type as order_type,
        'med_order' as order_source,
        med.displayed_medication_name as order_name,
        med.med_start_date as start_date,
        med.creation_date,
        med.created_by_user_id,
        iff(fill.med_order_id is not null, 'fulfilled', NULL) as order_status,
        max(fill.last_fill_date) as last_fulfilled_date
    from dw_dev.dev_jkizer_staging.stg_elation_med_order med  
    left join dw_dev.dev_jkizer_staging.stg_elation_med_order_fill fill on fill.med_order_id = med.med_order_id 
    group by all 

    union all 

    select 
        order_id, 
        elation_id,
        order_type,
        'misc_order' as order_source,
        test_name as order_name,
        creation_date as start_date,
        creation_date, 
        created_by_user_id,
        resolution_state as order_status, 
        iff(resolution_state = 'fulfilled', creation_date, NULL) as last_fulfilled_date
    from dw_dev.dev_jkizer_staging.stg_elation_misc_order  
    -- there are duplicates in misc_order, take the latest record per order_id
    qualify row_number() over (partition by elation_id, order_id order by creation_date desc) = 1    


    union all 

    select
        referral_id as order_id, 
        elation_id, 
        recipient_specialty as order_type,
        'referral_order' as order_source,
        referral_body_text as order_name,
        creation_date as start_date,
        creation_date, 
        created_by_user_id,
        resolution_state as order_status, 
        iff(resolution_state = 'fulfilled', creation_date, NULL) as last_fulfilled_date
    from  dw_dev.dev_jkizer.int_elation_referral

    union all 

    select
        lab.lab_order_id as order_id,
        lab.elation_id,
        lab.lab_vendor as order_type,
        'lab_order' as order_source,
        listagg(test.order_test_name, ',' ) as order_name, 
        lab.creation_date as start_date,
        lab.creation_date,
        lab.created_by_user_id,
        lab.order_state as order_status, 
        iff(lab.order_state = 'fulfilled', creation_date, NULL) as last_fulfilled_date
    from dw_dev.dev_jkizer_staging.stg_elation_lab_order lab
    left join dw_dev.dev_jkizer_staging.stg_elation_lab_order_tests test on test.lab_order_id = lab.lab_order_id
    group by all 
)

select 
    md5(cast(coalesce(cast(cd.order_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cd.order_source as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cd.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as all_orders_skey, 
    cd.order_id, 
    cd.elation_id, 
    suvida_id.suvida_id,
    concat(patient.first_name, ' ', patient.last_name) as patient_name,
    cd.order_type, 
    cd.order_source,
    cd.order_name, 
    cd.start_date, 
    cd.creation_date,
    cd.created_by_user_id, 
    user.user_name as created_by_staff_name, 
    cd.order_status, 
    cd.last_fulfilled_date
from combined_data cd
left join dw_dev.dev_jkizer.suvida_id_walk suvida_id 
    on suvida_id.member_id = cd.elation_id 
    and suvida_id.source = 'Elation'
left join dw_dev.dev_jkizer_staging.stg_elation_user user 
    on user.user_id = cd.created_by_user_id
left join dw_dev.dev_jkizer_staging.stg_elation_patient patient
    on patient.elation_id = cd.elation_id 
    and patient.source = 'Elation'
group by all