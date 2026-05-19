
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_program_enrollment
    copy grants
    
    
    as (with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -18, current_date()) and current_date()
),

-- mh_t_enrollment
mh_t_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'mh' as enrollment_team,
        'mh_t_individual' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_start
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where fd.source_type = 'emr'
    and 
        (fd.icd_10_code ilike '%f42%' or
        fd.icd_10_code ilike '%f20%' or
        fd.icd_10_code ilike '%f25%' or
        fd.icd_10_code ilike '%f31%' or
        fd.icd_10_code ilike '%f33%')
    and (fa.appointment_type ilike '%mh t%')
    and fa.appointment_provider_name in ('Melissa Rivera', 'Sarah Torrez', 'Jimmy Alcala', 'Lourdes Mendicuti', 'Maritza Hernandez', 'Nydia Rios', 'Jennifer Vazquez')
    and 
        (fa.appointment_date <= current_date())
    and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

-- mh_group_enrollment
mh_t_group_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'mh' as enrollment_team,
        'mh_t_group' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_start
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where fd.source_type = 'emr'
 /*   and (fd.icd_10_code = 'F4321') */
    and 
        (fa.appointment_type in ('MH Workshop', 'Viviendo con el Duelo') )
    and 
        (fa.appointment_date <= current_date())
    and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

-- mh_p_enrollment
mh_p_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'mh' as enrollment_team,
        'mh_p' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_start
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where fd.source_type = 'emr'
    and 
        (fd.icd_10_code ilike '%f42%' or
        fd.icd_10_code ilike '%f20%' or
        fd.icd_10_code ilike '%f25%' or
        fd.icd_10_code ilike '%f31%' or
        fd.icd_10_code ilike '%f33%')
    and (fa.appointment_type ilike '%mh p%')
    and fa.appointment_provider_name in ('Melissa Rivera', 'Sarah Torrez', 'Jimmy Alcala', 'Lourdes Mendicuti', 'Maritza Hernandez', 'Nydia Rios', 'Jennifer Vazquez')
    and 
        (fa.appointment_date <= current_date())
    and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pt_stroke_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pt' as enrollment_team,
        'post_stroke' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        source_type = 'emr'
      and 
        (fd.icd_10_code ilike '%i60%' or fd.icd_10_code ilike '%i61%'or
        fd.icd_10_code ilike '%i62%'or fd.icd_10_code ilike '%i63%'or
        fd.icd_10_code ilike '%i64%'or fd.icd_10_code ilike '%g45%'or
        fd.icd_10_code ilike '%g81%'
        )
      and 
        appointment_provider_name in ('Rita Zapien Miles', 'Zachary Carithers', 'Guillermo Moto', 'Ivana Cavazo', 'Adriana Salas', 'Joy Botros', 'Jennifer Pineda Velazquez', 'Ramiro Escalera')

      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pt_mob_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pt' as enrollment_team,
        'matter_of_balance' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    where appointment_provider_name ilike '%Group Session%'
      and 
        (fa.appointment_type_category = 'Matter of Balance')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

-- rd_enrollment
rd_enrollment_subienestar as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'rd' as enrollment_team,
        'subienestar' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    where appointment_provider_name ilike '%Group Session%'
      and 
        (fa.appointment_type_category ilike '%SuBienestar Class%')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

rd_enrollment_foodrx as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'rd' as enrollment_team,
        'food_rx' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    where 
        (appointment_provider_name ilike 'group session%')
      and 
        (fa.appointment_type_category ilike '%Food RX%')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
), 

rd_enrollment_htn as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'rd' as enrollment_team,
        'hypertension' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        (fd.source_type ilike 'emr')
    and    
        (fd.icd_10_code ilike '%i10%')      -- htn icd 10 same as pharmd
    and 
        appointment_provider_name in ('Otoniel Santiago', 'Karla Ortiz Conde', 'Stephanie Seekamp', 'Christy Wilson', 'Javier Aldam', 'Monica Sanchez', 'Jennifer Pineda Velazquez', 'Rita Zapien Miles')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

rd_enrollment_dm as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'rd' as enrollment_team,
        'diabetes' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        (fd.source_type ilike 'emr')
    and    
        (fd.icd_10_code ilike '%i10%')
    and 
        appointment_provider_name in ('Otoniel Santiago', 'Karla Ortiz Conde', 'Stephanie Seekamp', 'Christy Wilson', 'Javier Aldam', 'Monica Sanchez', 'Jennifer Pineda Velazquez', 'Rita Zapien Miles')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),
rd_enrollment_hyperlipidemia as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'rd' as enrollment_team,
        'hyperlipidemia' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        (fd.source_type ilike 'emr')
    and    
        (fd.icd_10_code ilike '%e78%' or
        fd.icd_10_code ilike '%781'or
        fd.icd_10_code ilike '%782'or
        fd.icd_10_code ilike '%783')
      and 
        appointment_provider_name in ('Otoniel Santiago', 'Karla Ortiz Conde', 'Stephanie Seekamp', 'Christy Wilson', 'Javier Aldam', 'Monica Sanchez', 'Jennifer Pineda Velazquez', 'Rita Zapien Miles')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

rd_enrollment_mnt as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'rd' as enrollment_team,
        'malnutrition' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        (fd.source_type ilike 'emr')
    and    
        (fd.icd_10_code ilike '%e43%' or 
        fd.icd_10_code ilike '%e44%' or
        fd.icd_10_code ilike '%r634%')
    and 
        appointment_provider_name in ('Otoniel Santiago', 'Karla Ortiz Conde', 'Stephanie Seekamp', 'Christy Wilson', 'Javier Aldam', 'Monica Sanchez', 'Jennifer Pineda Velazquez', 'Rita Zapien Miles')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

/* -- To be added for RD 
            baseline_labs
                            */
pharmd_dm_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pharmd' as enrollment_team,
        'diabetes' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_start
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 1 = 1
   /* and
        (fd.source_type ilike 'emr')
    and
        (fd.icd_10_code ilike '%e119%' */       -- need additional icd 10 codes
    and 
        appointment_provider_name in ('Chelsea Herrarte', 'Bianca Romero', 'Greissy Jerezano', 'Isabella Serranto')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pharmd_htn_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pharmd' as enrollment_team,
        'hypertension' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        (fd.source_type ilike 'emr')
    and
        (fd.icd_10_code ilike '%i10%')
    and 
        appointment_provider_name in ('Chelsea Herrarte', 'Bianca Romero', 'Greissy Jerezano', 'Isabella Serranto')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pharmd_chf_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pharmd' as enrollment_team,
        'chf' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_diagnosis fd
        on fa.suvida_id = fd.suvida_id
        and fa.appointment_date >= fd.diagnosis_date
    where 
        (fd.source_type ilike 'emr')
    and
        (fd.icd_10_code ilike '%i509%')
    and 
        appointment_provider_name in ('Chelsea Herrarte', 'Bianca Romero', 'Greissy Jerezano', 'Isabella Serranto')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pharmd_polypharm_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pharmd' as enrollment_team,
        'polypharm' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_quality_measure fqm
        on fa.suvida_id = fqm.suvida_id
        and fa.appointment_date >= fqm.report_date
    where 
        (fqm.quality_measure = 'Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults')
    and 
        (fqm.measure_numerator = 0 and fqm.measure_denominator = 1) 
    and 
        appointment_provider_name in ('Chelsea Herrarte', 'Bianca Romero', 'Greissy Jerezano', 'Isabella Serranto')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pharmd_supcd_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pharmd' as enrollment_team,
        'statin_cvd' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_quality_measure fqm
        on fa.suvida_id = fqm.suvida_id
        and fa.appointment_date >= fqm.report_date
    where 
        (fqm.quality_measure = 'Statin Therapy for Cardiovascular Disease')
    and 
        (fqm.measure_numerator = 0 and fqm.measure_denominator = 1) 
    and 
        appointment_provider_name in ('Chelsea Herrarte', 'Bianca Romero', 'Greissy Jerezano', 'Isabella Serranto')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

pharmd_supd_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        'pharmd' as enrollment_team,
        'supd' as enrollment_program,
        count(distinct iff(fa.appointment_date >= dateadd(month, -4, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_4_months,
        count(distinct iff(fa.appointment_date >= dateadd(month, -12, tp.date_month_start), fa.appointment_skey, null)) as visits_in_last_12_months,
        to_varchar(array_agg(fa.appointment_provider_name) within group (order by fa.appointment_date desc)[0]) as most_recent_provider,
        max(fa.appointment_date) as most_recent_appointment,
        null as tag_value,
        'visit' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_appointment fa 
        on fa.appointment_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    inner join dw_dev.dev_jkizer.fct_quality_measure fqm
        on fa.suvida_id = fqm.suvida_id
        and fa.appointment_date >= fqm.report_date
    where 
        (fqm.quality_measure = 'Statin Use in Persons with Diabetes')
    and 
        (fqm.measure_numerator = 0 and fqm.measure_denominator = 1) 
    and 
        appointment_provider_name in ('Chelsea Herrarte', 'Bianca Romero', 'Greissy Jerezano', 'Isabella Serranto')
      and 
        (fa.appointment_date <= current_date())
      and 
        (fa.appointment_status not ilike '%cancelled%' and fa.appointment_status not ilike '%notseen%')
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
                        
),

-- tag_enrollment
tag_enrollment as (
    select
        tp.date_month_start,
        tp.date_month_end,
        pt.suvida_id,
        mt.team,
        mt.program,
        null as visits_in_last_4_months,
        null as visits_in_last_12_months,
        null as most_recent_provider,
        null as most_recent_appointment,
        listagg(distinct pt.tag_value, ' | ') as tag_value,
        'tag' as enrollment_type
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_patient_tag pt on 1 = 1
    inner join dw_dev.dev_jkizer_source.map_tag_clinical_team_program mt
        on pt.tag_value = mt.clinical_program_tag
    where pt.suvida_id is not null
      and pt.creation_datetime <= tp.date_month_end
      and (pt.deletion_datetime >= tp.date_month_start or pt.deletion_datetime is null)
    group by tp.date_month_start, tp.date_month_end, pt.suvida_id, mt.team, mt.program
),

-- union of all cohorts
combined_data as (
    select * from mh_t_enrollment where visits_in_last_4_months >= 1
    union all
    select * from mh_t_group_enrollment where visits_in_last_4_months >= 1
    union all
    select * from mh_p_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pt_stroke_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pt_mob_enrollment where visits_in_last_4_months >= 1
    union all
    select * from rd_enrollment_subienestar where visits_in_last_4_months >= 1
    union all
    select * from rd_enrollment_foodrx where visits_in_last_4_months >= 1
    union all
    select * from rd_enrollment_htn where visits_in_last_4_months >= 1
    union all
    select * from rd_enrollment_dm where visits_in_last_4_months >= 1
    union all
    select * from rd_enrollment_hyperlipidemia where visits_in_last_4_months >= 1
    union all
    select * from rd_enrollment_mnt where visits_in_last_4_months >= 1
    union all
    select * from pharmd_dm_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pharmd_htn_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pharmd_chf_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pharmd_polypharm_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pharmd_supcd_enrollment where visits_in_last_4_months >= 1
    union all
    select * from pharmd_supd_enrollment where visits_in_last_4_months >= 1
    union all
    select * from tag_enrollment
),
final as (
select
    md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(date_month_start as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(date_month_end as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(enrollment_team as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(enrollment_program as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(enrollment_type as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as clinical_program_enrollment_skey,
    cd.*,
    iff(lag(suvida_id) over (partition by enrollment_team, enrollment_program, suvida_id, enrollment_type order by date_month_start) is null, true, false) as is_newly_enrolled
from combined_data cd
where visits_in_last_4_months is not null or enrollment_type = 'tag'
)

select
    * 
from final
    )
;


  