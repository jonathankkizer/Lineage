with 

alignment_revenue as (

    select * from dw_dev.dev_jkizer_staging.stg_alignment_revenue

),

alignment_assignment as (

    select * from dw_dev.dev_jkizer_staging.stg_alignment_assignment

),

suvida_id_walk as (

    select * from dw_dev.dev_jkizer.suvida_id_walk

),

-- =============================================================================
-- ASSIGNMENT
-- Latest assignment record per member for plan and payer metadata.
-- =============================================================================

assignment_latest as (

    select
        member_id,
        first_name,
        last_name,
        concat(first_name, ' ', last_name) as patient_full_name,
        birth_date as dob,
        pcp_npi,
        benefit_option as source_lob,
        pbp_code,
        contract_plan_id,
        payer_parent,
        payer_name,
        payer_contract
    from alignment_assignment
    where patient_report_index = 1

),

-- =============================================================================
-- REVENUE
-- Sums premium across all files per member per pay period to capture
-- adjustments arriving in subsequent monthly files.
-- =============================================================================

revenue_by_month as (

    select
        member_id,
        pay_period_date as effective_month,
        sum(premium) * 0.85 as premium_credit,
        max(src_file_date) as report_date,
        source
    from alignment_revenue
    group by all

),

-- =============================================================================
-- FINAL
-- =============================================================================

final as (

    select
        suvida_id_walk.suvida_id,
        revenue_by_month.member_id,
        assignment_latest.first_name,
        assignment_latest.last_name,
        assignment_latest.patient_full_name,
        assignment_latest.dob,
        revenue_by_month.effective_month,
        assignment_latest.source_lob,
        assignment_latest.pcp_npi,
        revenue_by_month.source,
        revenue_by_month.report_date,
        row_number() over (
            partition by revenue_by_month.member_id, revenue_by_month.effective_month
            order by revenue_by_month.report_date desc
        ) as report_date_index,
        revenue_by_month.premium_credit,
        assignment_latest.pbp_code,
        assignment_latest.contract_plan_id,
        assignment_latest.payer_parent,
        assignment_latest.payer_name,
        assignment_latest.payer_contract
    from revenue_by_month
    left join assignment_latest
        on revenue_by_month.member_id = assignment_latest.member_id
    left join suvida_id_walk
        on revenue_by_month.member_id = suvida_id_walk.member_id
        and revenue_by_month.source = suvida_id_walk.source

)

select * from final