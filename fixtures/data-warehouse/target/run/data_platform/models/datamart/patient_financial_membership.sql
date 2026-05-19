
  
    

create or replace transient table dw_dev.dev_jkizer.patient_financial_membership
    copy grants
    
    
    as (with data as (
    select 
    -- one row per member per financial membership month
        md5(cast(coalesce(cast(fmm.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fmm.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fmm.financial_member_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fmm.pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as financial_membership_skey, 
        fmm.financial_member_month,
        monthname(fmm.financial_member_month) as month_name,
        fmm.suvida_id, 
        fmm.member_id,
        fmm.first_name,
        fmm.last_name,
        fmm.patient_full_name,
        fmm.dob,
        fmm.source as financial_source,
        fmm.part_c_net_premium,
        fmm.part_d_net_premium,
        fmm.part_d_expense,
        dp_fin.provider_name as financial_provider_name,
        dp_fin.location_name as financial_location_name,
        coalesce(fmm.plan_network_type, dep.plan_network_type) as plan_network_type,
        coalesce(fmm.plan_program_type, dep.plan_program_type) as plan_program_type,
        coalesce(fmm.plan_network_program_type, dep.plan_network_program_type) as plan_network_program_type,
        fmm.source_lob,
        coalesce(fmm.pbp_code, dep.plan_code) as pbp_code,
        coalesce(fmm.plan_name, dep.plan_name) as plan_name,
        true as is_financial_membership_month,
        1 as financial_member_month_ind,
        iff(fam.suvida_id is not null, true, false) as is_patient_assigned_month,
        dep.report_date as assignment_report_date,
        fmm.payer_parent,
        fmm.payer_name,
        fmm.payer_contract,
    from dw_dev.dev_jkizer.intmdt_financial_member_month fmm 
    left join dw_dev.dev_jkizer.dim_provider dp_fin
        on fmm.pcp_npi = dp_fin.npi
    left join dw_dev.dev_jkizer.fct_assignment_month fam 
        on fmm.suvida_id = fam.suvida_id
        and fmm.financial_member_month = fam.assignment_month
        and fmm.source = fam.source
    left join dw_dev.dev_jkizer.dim_assignment_patient dep 
        on fam.member_file_skey = dep.member_file_skey
    where is_most_recent_report = true 
    group by all
    qualify row_number() over (partition by fmm.suvida_id, fmm.member_id, fmm.financial_member_month order by dep.report_date desc) = 1 -- guarantees one record per patient per month, using the latest record for each month
    
    union all
    /* add United, which doesn't have a traditional financial membership file, so we assume assignment = financial membership */
    select
        md5(cast(coalesce(cast(fmm.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fmm.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fmm.mmr_month as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as financial_membership_skey,
        fmm.mmr_month as financial_member_month,
        monthname(fmm.mmr_month) as month_name,
        fmm.suvida_id, 
        fmm.member_id as assignment_member_id,
        null as first_name,
        null as last_name,
        null as patient_full_name,
        null as dob,
        fmm.mmr_source as financial_source,
        null as part_c_net_premium,
        null as part_d_net_premium,
        null as part_d_expense,
        fam.assignment_provider_name as financial_provider_name,
        fam.assignment_location_name as financial_location_name,
        fam.plan_network_type,
        fam.plan_program_type,
        fam.plan_network_program_type,
        coalesce(fam.source_lob, fmm.source_lob) as source_lob,
        fmm.pbp_code,
        fam.plan_name as plan_name,
        true as is_financial_membership_month,
        1 as financial_member_month_ind,
        true as is_patient_assigned_month,
        null as assignment_report_date,
        fmm.payer_parent,
        fmm.payer_name,
        fmm.payer_contract,
    from dw_dev.dev_jkizer.fct_mmr_month fmm
    left join dw_dev.dev_jkizer.patient_assignment fam
        on fmm.suvida_id = fam.suvida_id
        and fmm.mmr_month = fam.date_month
        and fmm.mmr_source = fam.assignment_source
    where fmm.mmr_source in ('United', 'United TX') and (fmm.suvida_id_mmr_rank = 1 or (fmm.suvida_id is null and fmm.member_id_mbi_mmr_rank = 1))
), monthly_files as ( -- generate array of the most recent eligibility files received in each month
    select 
        suvida_id,
        member_id,
        financial_member_month,
    from data pa
), groupings as ( -- rank and get the most recent previous report for each member
    select 
        dense_rank() over (partition by coalesce(suvida_id, member_id) order by financial_member_month) as rn,
        suvida_id,
        member_id,
        financial_member_month,
        lag(financial_member_month, 1) over (partition by coalesce(suvida_id, member_id) order by financial_member_month) as _prev_date_month
    from monthly_files
    qualify row_number() over (partition by coalesce(suvida_id, member_id), financial_member_month order by member_id desc) = 1
), island_id as ( -- flag if the max time delta between current record's month and previous is <= 1 month
    select
        *,
        case when datediff(month, _prev_date_month, financial_member_month) <= 1 then 0 else 1 end as island_start_ind,
        sum(case when datediff(month, _prev_date_month, financial_member_month) <= 1 then 0 else 1 end) over (partition by coalesce(suvida_id, member_id) order by rn) as island_id
    from groupings
), island_id_start as (
    select 
        * 
    from island_id
    where island_start_ind = 1
), max_month_per_id as (
    select
        suvida_id,
        island_id,
        max(financial_member_month) as financial_member_month,
        dateadd(month, 1, max(financial_member_month)) as next_month,
    from island_id
    group by suvida_id, island_id
    having max(financial_member_month) <= dateadd(month, -3, current_date())
), full_data as (
    select
        md5(cast(coalesce(cast(mmpi.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_month as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as financial_membership_skey,
        next_month as financial_member_month,
        monthname(next_month) as month_name,
        mmpi.suvida_id,
        null as member_id,
        null as first_name,
        null as last_name,
        null as patient_full_name,
        null as dob,
        null as financial_source,
        null as part_c_net_premium,
        null as part_d_net_premium,
        null as part_d_expense,
        null as financial_provider_name,
        null as financial_location_name,
        null as plan_network_type,
        null as plan_program_type,
        null as plan_network_program_type,
        null as source_lob,
        null as pbp_code,
        null as plan_name,
        false as is_financial_membership_month,
        0 as financial_member_month_ind,
        false as is_patient_assigned_month,
        null as payer_parent,
        null as payer_name,
        null as payer_contract,
        md5(cast(coalesce(cast(ii.island_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(mmpi.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as cohort_id,
        iis.financial_member_month as cohort_start_date
    from max_month_per_id mmpi
    left join island_id ii 
        on mmpi.suvida_id = ii.suvida_id
        and mmpi.financial_member_month = ii.financial_member_month
    left join island_id_start iis 
        on mmpi.suvida_id = iis.suvida_id
        and ii.island_id = iis.island_id
    
    union all 
    
    select
        d.* exclude (assignment_report_date),
        md5(cast(coalesce(cast(ii.island_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(d.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as cohort_id,
        iis.financial_member_month as cohort_start_month
    from data d
    left join island_id ii 
        on d.suvida_id = ii.suvida_id
        and d.financial_member_month = ii.financial_member_month
    left join island_id_start iis 
        on d.suvida_id = iis.suvida_id
        and ii.island_id = iis.island_id
), lag_inds as (
    select
        *,
        coalesce(lag(financial_member_month_ind) over (partition by suvida_id order by financial_member_month asc), 0) as prev_month_financial_member_month_ind,
        coalesce(lag(financial_member_month_ind, 3) over (partition by suvida_id order by financial_member_month asc), 0) as prev_3_month_financial_member_month_ind,
        lag(financial_source) over (partition by suvida_id order by financial_member_month asc) as prev_month_financial_source,
    from full_data
), financial_membership_bucket as (
    select 
        *,
        case
            when financial_member_month_ind = 1 and prev_month_financial_member_month_ind = 0 and prev_3_month_financial_member_month_ind = 0 then 'new'
            when financial_member_month_ind = 1 and prev_month_financial_member_month_ind = 0 and prev_3_month_financial_member_month_ind = 1 then 'resume'
            when financial_member_month_ind = 1 and prev_month_financial_member_month_ind = 1 then 'active'
            when financial_member_month_ind = 1 and prev_month_financial_member_month_ind = 0 then 'new'
            when financial_member_month_ind = 0 and prev_month_financial_member_month_ind = 1 then 'lost'
            when financial_member_month_ind = 0 and prev_month_financial_member_month_ind = 0 then 'no_assignment'
        end as financial_membership_bucket,
        count(iff(financial_member_month_ind = 1, financial_membership_skey, null)) over (partition by financial_member_month) as monthly_membership_count, 
        count(iff(financial_member_month_ind = 1, financial_membership_skey, null)) over (partition by date_trunc(year, financial_member_month)) as yearly_membership_count, 
    from lag_inds
)
select
    * exclude (financial_source),
    case 
        when month(financial_member_month) in (1,2,3) then year(financial_member_month) || 'Q1'
        when month(financial_member_month) in (4,5,6) then year(financial_member_month) || 'Q2'
        when month(financial_member_month) in (7,8,9) then year(financial_member_month) || 'Q3'
        when month(financial_member_month) in (10,11,12) then year(financial_member_month) || 'Q4'
    end as financial_member_month_quarter,
    iff(financial_membership_bucket = 'resume' or prev_month_financial_member_month_ind = 1, 1, 0) as churn_denominator_ind,
    coalesce(financial_source, prev_month_financial_source) as financial_source,
    case 
        when coalesce(financial_source, prev_month_financial_source) = 'UHG/Wellmed' then concat('Wellmed',' ', source_lob)
        when coalesce(financial_source, prev_month_financial_source) = 'Wellcare/Centene' then 'Wellcare'
        else concat(coalesce(financial_source, prev_month_financial_source), ' ', source_lob)
    end as display_lob,
    iff(date_trunc('month', financial_member_month) between dateadd(month, -15, date_trunc(month, current_date())) and dateadd(month, -3, date_trunc(month, current_date())), true, false) as is_claim_rolling_12_window,
from financial_membership_bucket
    )
;


  