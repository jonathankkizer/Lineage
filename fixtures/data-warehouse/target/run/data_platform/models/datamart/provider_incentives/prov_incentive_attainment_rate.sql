
  
    

create or replace transient table dw_dev.dev_jkizer.prov_incentive_attainment_rate
    copy grants
    
    
    as (-- Logic of this data model follows mockup: https://lunamedholdings.sharepoint.com/:x:/r/sites/SuvidaUniversity1/Shared%20Documents/Shared%20Operations/2024Q4%20Goal%20%26%20Incentive%20Support/2025%20Provider%20Incentive%20Mockup.xlsx?d=w10a4c4e8596241ab914410db071354fa&csf=1&web=1&e=eiy5cS 
-- Omar's requirements for all measures:
-- Only include patients with at least 1 PCP visit YTD
-- Med Adherence measures are directly from payer files
-- Redocumentation of HCC codes are from Elation 
-- A1C and HBP measures take the greatest of Elation and Payer files, denominator will always be Payer
with combined as (

    select 
        measure_year as bonus_year,
        prov.provider_name,
        measure_group,
        measure_name,
        sum(measure_numerator) as passing_patients,
        sum(measure_denominator) as eligible_patients,
        sum(measure_numerator*1.0) / sum(measure_denominator*1.0) as perc_passing
    from dw_dev.dev_jkizer.prov_incentive_combined prov
    inner join dw_dev.dev_jkizer.patient_summary patient 
        on patient.suvida_id = prov.suvida_id
    where measure_name not in ('echo_screening', 'pvd_screening') 
    and prov.num_pcp_visits_ytd_group != '0 visits'
    and patient.is_active_assignment = 1
    and measure_year >= 2023
    group by all
), 

all_providers as (
-- force one row per measure per year
    select 
        dim.provider_name, 
        rate.measure_name, 
        years.bonus_year
    from dw_dev.dev_jkizer.dim_provider dim
    cross join dw_dev.dev_jkizer_source.map_prov_incentive_2025_bonus rate 
    cross join (
        select value as bonus_year
        from table(flatten(array_generate_range(2023, year(current_date)+1)))
    ) years
    where dim.is_actively_seeing_patients = true
)

select 
    dim.bonus_year,
    dim.provider_name,
    case when dim.measure_name = 'a1c_control' then 'Diabetic A1C Control'
        when dim.measure_name = 'awv_completion' then '% Active Patients with AWV'
        when dim.measure_name = 'hbp_control' then 'Controlling High Blood Pressure'
        when dim.measure_name = 'redocumentation' then 'Redocumentation %'
        when dim.measure_name = 'visit_note_closure' then '% Notes Closed in 7 Days'
        else dim.measure_name
    end as measure_name,
    passing_patients,
    eligible_patients,
    perc_passing,
    case when perc_passing >= max_cutpoint then 1 
        when perc_passing between partial_cutpoint and max_cutpoint then (perc_passing/max_cutpoint)*1.0
        else 0 
    end as pct_measure_earned, 
    (case when perc_passing >= max_cutpoint then 1 
        when perc_passing between partial_cutpoint and max_cutpoint then (perc_passing/max_cutpoint)*1.0
        else 0 end) * weight as pct_measure_weight_earned,
    sum((case when perc_passing >= max_cutpoint then 1 
        when perc_passing between partial_cutpoint and max_cutpoint then (perc_passing/max_cutpoint)*1.0
        else 0 end) * weight) over (partition by combined.bonus_year, dim.provider_name) as total_bonus_attainment_rate
from all_providers dim
left join combined on combined.provider_name = dim.provider_name and combined.measure_name = dim.measure_name and combined.bonus_year = dim.bonus_year
left join dw_dev.dev_jkizer_source.map_prov_incentive_2025_bonus rate 
    on rate.measure_name = combined.measure_name
    )
;


  