with spiro_exclusions as (
        select 
            suvida_id
        from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis
        where hcc_model = 24
        and source_type = 'emr'
        and period_type = 'rolling_24_month'
        and hcc_code in ('HCC111','HCC112','HCC84','HCC110')
    ),
    cte_eligibility as (
    select 
        suvida_id   
    from dw_dev.dev_jkizer.patient_history 
    where smoker_status_value in ('Smoker, current status unknown','Former smoker','Current every day smoker','Current some day smoker','Heavy tobacco smoker','Light tobacco smoker')
    )
    select 
        ce.suvida_id,
        co.signed_date as evidence_date,
        year(co.signed_date) as evidence_year,
        concat(co.test_name, '; ', co.resolution_state, '; ', co.signed_date) as evidence_desc,
        CASE 
            WHEN lower(co.resolution_state) = 'fulfilled' THEN 1
            ELSE 0 
        END AS suvida_numerator,
        1 as suvida_denominator,
        0 as pending_numerator,
        'suvida-spiro' as quality_measure,
        
        object_construct(
            'evidence_date', co.signed_date,
            'evidence_string', co.test_score
				) as evidence_array
    from cte_eligibility ce
    left join spiro_exclusions se 
    on ce.suvida_id = se.suvida_id
    left join 
    dw_dev.dev_jkizer.fct_misc_orders co 
    on ce.suvida_id = co.suvida_id
    and  lower(co.test_name) like '%spiro%'
    where  se.suvida_id is null
    qualify row_number() over(partition by ce.suvida_id order by ce.suvida_id) = 1