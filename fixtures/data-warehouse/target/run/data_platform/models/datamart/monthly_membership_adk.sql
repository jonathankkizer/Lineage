
  
    

create or replace transient table dw_dev.dev_jkizer.monthly_membership_adk
    copy grants
    
    
    as (with member_months_by_month as (
    select
        member_month as month,
        count(distinct case when has_active_membership = 1 then member_month_skey end) as active_member_months,
        -- Adjust current month by day completion percentage
        case
            when member_month = date_trunc(month, current_date())
            then count(distinct case when has_active_membership = 1 then member_month_skey end)
                * dayofmonth(current_date()) / dayofmonth(last_day(current_date(), month))
            else count(distinct case when has_active_membership = 1 then member_month_skey end)
        end as adjusted_active_member_months,
    from dw_dev.dev_jkizer.patient_member_month
    where member_month >= '2022-11-01' -- First month of Suvida
    and member_month <= date_trunc(month, current_date())
    group by member_month
), inpatient_admits_by_month as (
    select
        date_trunc('month', pie.admit_date) as month,
        count(distinct pie.patient_inpatient_encounter_skey) as total_inpatient_admits,
    from dw_dev.dev_jkizer.patient_inpatient_encounter pie
    inner join dw_dev.dev_jkizer.patient_member_month pmm
        on pie.suvida_id = pmm.suvida_id
        and date_trunc('month', pie.admit_date) = pmm.member_month
        and pmm.has_active_membership = 1
    where pie.is_airtable_only_admission = false
    and date_trunc('month', pie.admit_date) >= '2022-11-01'
    and date_trunc('month', pie.admit_date) <= date_trunc(month, current_date())
    group by date_trunc('month', pie.admit_date)
), census_admits_by_month as (
    select
        pce.admit_month as month,
        count(distinct pce.census_grouping_id) as total_census_admits,
    from dw_dev.dev_jkizer.patient_census_event pce
    inner join dw_dev.dev_jkizer.patient_member_month pmm
        on pce.suvida_id = pmm.suvida_id
        and pce.admit_month = pmm.member_month
        and pmm.has_active_membership = 1
    where pce.is_inpatient = 1
    and pce.source_types != 'Airtable Manual Entry'
    and pce.admit_month >= '2022-11-01'
    and pce.admit_month <= date_trunc(month, current_date())
    group by pce.admit_month
), monthly_adk as (
    select
        coalesce(mm.month, ia.month, ca.month) as month,
        coalesce(mm.active_member_months, 0) as active_member_months,
        coalesce(mm.adjusted_active_member_months, 0) as adjusted_active_member_months,
        coalesce(ia.total_inpatient_admits, 0) as total_inpatient_admits,
        coalesce(ca.total_census_admits, 0) as total_census_admits,
        div0(coalesce(ia.total_inpatient_admits, 0), coalesce(mm.active_member_months, 0)) * 1000 * 12 as inpatient_adk,
        div0(coalesce(ca.total_census_admits, 0), coalesce(mm.adjusted_active_member_months, 0)) * 1000 * 12 as census_inpatient_adk,
        -- Only calculate ratio for months using financial membership (not in last 3 months)
        case
            when coalesce(mm.month, ia.month, ca.month) < dateadd(month, -3, date_trunc(month, current_date()))
            then div0(
                div0(coalesce(ia.total_inpatient_admits, 0), coalesce(mm.active_member_months, 0)) * 1000 * 12,
                div0(coalesce(ca.total_census_admits, 0), coalesce(mm.adjusted_active_member_months, 0)) * 1000 * 12
            )
            else null
        end as adk_ratio,
    from member_months_by_month mm
    full outer join inpatient_admits_by_month ia
        on mm.month = ia.month
    full outer join census_admits_by_month ca
        on mm.month = ca.month
), monthly_adk_with_rolling as (
    select
        month,
        active_member_months,
        adjusted_active_member_months,
        total_inpatient_admits,
        total_census_admits,
        inpatient_adk,
        census_inpatient_adk,
        adk_ratio,
        -- Calculate rolling average only for months where we have a ratio
        avg(adk_ratio) over (
            order by month
            rows between 2 preceding and current row
        ) as rolling_3mo_adk_ratio_calculated,
    from monthly_adk
    where adk_ratio is not null
), all_months as (
    select
        ma.month,
        ma.active_member_months,
        ma.adjusted_active_member_months,
        ma.total_inpatient_admits,
        ma.total_census_admits,
        ma.inpatient_adk,
        ma.census_inpatient_adk,
        ma.adk_ratio,
        mawr.rolling_3mo_adk_ratio_calculated,
    from monthly_adk ma
    left join monthly_adk_with_rolling mawr
        on ma.month = mawr.month
), last_rolling_value as (
    select
        rolling_3mo_adk_ratio_calculated as last_rolling_avg
    from monthly_adk_with_rolling
    order by month desc
    limit 1
)
select
    md5(cast(coalesce(cast(month as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as monthly_membership_adk_skey,
    month,
    monthname(month) as month_name,
    active_member_months,
    adjusted_active_member_months,
    total_inpatient_admits,
    total_census_admits,
    inpatient_adk,
    census_inpatient_adk,
    adk_ratio,
    -- Use calculated rolling average for months with ratio, carry forward last value for recent months
    coalesce(rolling_3mo_adk_ratio_calculated, (select last_rolling_avg from last_rolling_value)) as rolling_3mo_adk_ratio,
from all_months
order by month desc
    )
;


  