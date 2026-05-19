with date_spine as (
    select 
        date_day as month_start_date,
        last_day(date_day) as month_end_date,
    from dw_dev.dev_jkizer.dim_date 
    where is_bom = true
    and date_day >= '2022-09-01'
    and date_day <= current_date()
),
grouping_month_tag as(
select 
    suvida_id,
    iff(month_start_date = date_trunc('month', current_date()), true, false) as is_current_month,
    month_start_date,
    month_end_date,
    /*Food Rx and Nutrition */
    max(case when tag_value = 'Food RX' then 1 else 0 end) as food_rx,
    max(case when tag_value = 'Rx-Statin' then 1 else 0 end) as rx_statin,
    max(case when tag_value = 'Rx-ACE/ARB' then 1 else 0 end) as rx_ace_arb,
    max(case when tag_value = 'Rx-DM' then 1 else 0 end) as rx_dm,
    max(case when tag_value = 'RD-DM' then 1 else 0 end) as rd_dm,
    max(case when tag_value = 'Transportation Suvida' then 1 else 0 end) as transportation_suvida,
    max(case when tag_value = 'MedAdh Program' then 1 else 0 end) as med_adh_program,
    max(case when tag_value = 'RD-Services' then 1 else 0 end) as rd_services,
    /*Pharmacy*/
    max(case when tag_value = 'PharmD-DM' then 1 else 0 end) as pharm_dm,
    max(case when tag_value = 'PharmD-COPD' then 1 else 0 end) as pharm_copd,
    max(case when tag_value = 'PharmD-CHF' then 1 else 0 end) as pharm_chf,
    max(case when tag_value = 'PharmD-HTN' then 1 else 0 end) as pharm_htn,
    max(case when tag_value = 'Genoa Pharmacy' then 1 else 0 end) as pharm_genoa,
    /*SDOH */
    max(case when tag_value = 'Housing Insecurity' then 1 else 0 end) as housing_insecurity,
    max(case when tag_value = 'Food Insecurity' then 1 else 0 end) as food_insecurity,
    max(case when tag_value = 'Transportation Insecurity' then 1 else 0 end) as transportation_insecurity,
    max(case when tag_value = 'Financial Insecurity' then 1 else 0 end) as financial_insecurity,
    /* Mental Health */
    max(case when tag_value = 'MH-T' then 1 else 0 end) as mh_therapy,
    max(case when tag_value = 'MH-P' then 1 else 0 end) as mh_psych,
    max(case when tag_value = 'MH-TP' then 1 else 0 end) as mh_therapy_y_psych,
    max(case when tag_value = 'MH-Waitlist' then 1 else 0 end) as mh_waitlist,
    /*Misc */
    max(case when tag_value = 'LIS' then 1 else 0 end) as lis,
    max(case when tag_value = 'PAP' then 1 else 0 end) as pap,
from date_spine ds
inner join dw_dev.dev_jkizer.fct_patient_tag  fpt
    on fpt.creation_datetime < dateadd(day, 1, ds.month_end_date)
    and coalesce(fpt.deletion_datetime, current_date()) >= ds.month_start_date
where suvida_id is not null
group by all
)
select
    suvida_id,
    is_current_month,
    month_start_date,
    month_end_date,
    food_rx,
    rx_statin,
    rx_ace_arb,
    rx_dm,
    rd_dm,
    transportation_suvida,
    med_adh_program,
    rd_services,
    pharm_dm,
    pharm_copd,
    pharm_chf,
    pharm_htn,
    pharm_genoa,
    housing_insecurity,
    food_insecurity,
    transportation_insecurity,
    financial_insecurity,
    mh_therapy,
    mh_psych,
    mh_therapy_y_psych,
    mh_waitlist,
    lis,
    pap,
    case when (food_rx + rx_statin + rx_ace_arb + rx_dm + rd_dm + transportation_suvida + med_adh_program + rd_services) > 0 then 1 else 0 end as num_unique_patient_food_nutrition,
    case when (pharm_dm + pharm_copd + pharm_chf + pharm_htn + pharm_genoa) > 0 then 1 else 0 end as num_unique_patient_pharma,
    case when (housing_insecurity + food_insecurity + transportation_insecurity + financial_insecurity) >0 then 1 else 0 end as num_unique_patient_sdoh,
    case when (mh_therapy + mh_psych + mh_therapy_y_psych + mh_waitlist) >0 then 1 else 0 end as num_unique_patient_mental_health,
    case when (lis + pap) >0 then 1 else 0 end as num_unique_patient_misc,
    case when (food_rx + rx_statin + rx_ace_arb + rx_dm + rd_dm + transportation_suvida + med_adh_program + rd_services + pharm_dm + pharm_copd + pharm_chf + pharm_htn + pharm_genoa + housing_insecurity + food_insecurity + transportation_insecurity + financial_insecurity + mh_therapy + mh_psych + mh_therapy_y_psych + mh_waitlist + lis + pap) > 0 then 1 else 0 end as num_unique_patient_all_programs,
    food_rx + rx_statin + rx_ace_arb + rx_dm + rd_dm + transportation_suvida + med_adh_program + rd_services as num_enrollment_food_nutrition,
    pharm_dm + pharm_copd + pharm_chf + pharm_htn + pharm_genoa as num_enrollment_pharma,
    housing_insecurity + food_insecurity + transportation_insecurity + financial_insecurity as num_enrollment_sdoh,
    mh_therapy + mh_psych + mh_therapy_y_psych + mh_waitlist as num_enrollment_mental_health,
    lis + pap as num_enrollment_misc,
    food_rx + rx_statin + rx_ace_arb + rx_dm + rd_dm + transportation_suvida + med_adh_program + rd_services + pharm_dm + pharm_copd + pharm_chf + pharm_htn + pharm_genoa + housing_insecurity + food_insecurity + transportation_insecurity + financial_insecurity + mh_therapy + mh_psych + mh_therapy_y_psych + mh_waitlist + lis + pap as num_enrollment_all_programs
from grouping_month_tag
order by month_start_date