with alignment_mmr as (

    select * from dw_dev.dev_jkizer_staging.stg_alignment_mmr

),

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
-- RAF SCORE
-- Deduped risk adjustment factor per member per payment month.
-- Prefers latest file; ties broken by lower (more conservative) RAF type code.
-- =============================================================================

alignment_mmr_raf as (

    select distinct
        member_id,
        payment_date as mmr_month,
        risk_adjustment_factor_a as mmr_risk_score
    from alignment_mmr
    where mmr_file_recency_rank =1

),

-- =============================================================================
-- MMR RECORDS — ONE ROW PER MEMBER PER PAYMENT MONTH
-- Keeps the most recent file's record when a member appears in multiple files
-- for the same payment month.
-- =============================================================================

alignment_mmr_deduped as (

    select
        member_id,
        medicare_beneficiary_id,
        birth_date,
        payment_date as mmr_month,
        raf_type_code,
        original_reason_entitlement_code,
        esrd_ind,
        part_d_risk_raf,
        iff(medicaid_dual_status_code > 0, true, false) as dual_status_bool,
        src_file_date,
        source as mmr_source
    from alignment_mmr
    where mmr_file_recency_rank = 1

),

-- =============================================================================
-- REVENUE
-- Sums premium across all files for a given pay period to capture adjustments
-- that arrive in subsequent monthly files. mmr_revenue = sum(premium) * 85%.
-- =============================================================================

alignment_revenue_deduped as (

    select
        member_id,
        pay_period_date as mmr_month,
        sum(premium) * 0.85 as mmr_revenue
    from alignment_revenue
    group by all

),

-- =============================================================================
-- ASSIGNMENT
-- Latest assignment record per member for benefit_option and pbp_code.
-- =============================================================================

alignment_assignment_latest as (

    select
        member_id,
        benefit_option,
        pbp_code
    from alignment_assignment
    where patient_report_index = 1

),

-- =============================================================================
-- FINAL
-- Resolves suvida_id via suvida_id_walk.
-- =============================================================================

final as (

    select
        alignment_mmr_deduped.mmr_month,
        suvida_id_walk.suvida_id,
        alignment_mmr_deduped.medicare_beneficiary_id,
        alignment_mmr_deduped.member_id,
        alignment_mmr_deduped.birth_date,
        alignment_mmr_deduped.mmr_source,
        alignment_mmr_deduped.original_reason_entitlement_code::int::varchar as original_reason_entitlement_code,
        alignment_mmr_deduped.src_file_date as max_mmr_report_date,
        alignment_mmr_raf.mmr_risk_score,
        alignment_mmr_deduped.part_d_risk_raf as mmr_part_d_risk_score,
        alignment_mmr_deduped.raf_type_code,
        alignment_revenue_deduped.mmr_revenue,
        null as mmr_part_d_revenue,
        alignment_mmr_deduped.dual_status_bool,
        alignment_assignment_latest.benefit_option as source_lob,
        alignment_assignment_latest.pbp_code
    from alignment_mmr_deduped
    left join alignment_mmr_raf
        on alignment_mmr_deduped.member_id = alignment_mmr_raf.member_id
        and alignment_mmr_deduped.mmr_month = alignment_mmr_raf.mmr_month
    left join alignment_revenue_deduped
        on alignment_mmr_deduped.member_id = alignment_revenue_deduped.member_id
        and alignment_mmr_deduped.mmr_month = alignment_revenue_deduped.mmr_month
    left join alignment_assignment_latest
        on alignment_mmr_deduped.member_id = alignment_assignment_latest.member_id
    left join suvida_id_walk
        on alignment_mmr_deduped.member_id = suvida_id_walk.member_id
        and alignment_mmr_deduped.mmr_source = suvida_id_walk.source

)

select * from final