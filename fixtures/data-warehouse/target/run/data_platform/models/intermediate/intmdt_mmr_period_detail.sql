
  create or replace   view dw_dev.dev_jkizer.intmdt_mmr_period_detail
  
  copy grants
  
  
  as (
    

/*
    Intermediate MMR Period Detail

    This model unions MMR data from all payers with standardized column names,
    preserving both the cap period month (month being paid for) and process month
    (when payment was processed).

    Grain: member + cap_period_month + process_month (one row per payment transaction)

    Use cases:
    - Retroactive adjustment tracking (how payments for a cap period accumulate over time)
    - Cash flow analysis (revenue received by process month)
    - Payment lag analysis
    - Financial reconciliation
*/

with wellmed_mmr as (
    select
        -- Identifiers
        medicare_beneficiary_id,
        gmpi_id as member_id,
        gmpi_id,  -- Keep gmpi_id separately for patient linking
        subscriber_id,

        -- Time dimensions
        cap_period_month,
        process_month,

        -- Payment data (apply 0.96 contract adjustment to match fct_mmr_month_wellmed)
        net_payment_amount * 0.96 as net_payment_amount,

        -- Risk data
        raf_score,
        null::float as part_d_raf_score,
        raf_type_code,

        -- Adjustment metadata
        adj_code::varchar as adjustment_reason_code,
        current_retro_indicator,

        -- Source tracking
        src_file_name,
        src_file_date,
        'UHG/Wellmed' as source,

        -- Use staging model's deduplication rank (latest file per cap_period)
        mmr_process_month_report_rank as file_rank

    from dw_dev.dev_jkizer_staging.stg_wellmed_mmr
    where cap_period_month is not null
      and process_month is not null

), united_mmr as (
    select
        -- Identifiers
        null::varchar as medicare_beneficiary_id,
        member_id,
        null::varchar as gmpi_id,
        null::varchar as subscriber_id,

        -- Time dimensions
        apply_month as cap_period_month,
        payment_month as process_month,

        -- Payment data (gross_revenue * percent_of_payment adjustment)
        gross_revenue * percent_of_payment as net_payment_amount,

        -- Risk data
        raf_score::float as raf_score,
        null::float as part_d_raf_score,
        raf_type_code,

        -- Adjustment metadata
        adjustment_reason_code::varchar as adjustment_reason_code,
        null::varchar as current_retro_indicator,

        -- Source tracking
        src_file_name,
        src_file_date,
        source,

        -- Deduplication rank (latest file per cap_period + process_month combo)
        dense_rank() over (
            partition by member_id, apply_month, payment_month
            order by src_file_date desc
        ) as file_rank

    from dw_dev.dev_jkizer_staging.stg_united_az_mmr
    where apply_month is not null
      and payment_month is not null

    union all

    select
        -- Identifiers
        null::varchar as medicare_beneficiary_id,
        member_id,
        null::varchar as gmpi_id,
        null::varchar as subscriber_id,

        -- Time dimensions
        apply_month as cap_period_month,
        payment_month as process_month,

        -- Payment data (gross_revenue * percent_of_payment adjustment)
        gross_revenue * percent_of_payment as net_payment_amount,

        -- Risk data
        raf_score::float as raf_score,
        null::float as part_d_raf_score,
        raf_type_code,

        -- Adjustment metadata
        adjustment_reason_code::varchar as adjustment_reason_code,
        null::varchar as current_retro_indicator,

        -- Source tracking
        src_file_name,
        src_file_date,
        source,

        -- Deduplication rank (latest file per cap_period + process_month combo)
        dense_rank() over (
            partition by member_id, apply_month, payment_month
            order by src_file_date desc
        ) as file_rank

    from dw_dev.dev_jkizer_staging.stg_united_tx_mmr
    where apply_month is not null
      and payment_month is not null

), devoted_mmr as (
    -- Devoted has date ranges that need to be expanded into individual months
    -- Revenue calculation matches fct_mmr_month_devoted.sql
    select
        -- Identifiers
        dm.medicare_beneficiary_id,
        null::varchar as member_id,
        null::varchar as gmpi_id,
        null::varchar as subscriber_id,

        -- Time dimensions (expand date range into individual months)
        dd.date_day as cap_period_month,
        date_trunc('month', dm.payment_date)::date as process_month,

        -- Payment data: Devoted's MMR revenue flow per contract
        -- Uses risk-adjusted monthly rates, subtracts rebates, applies contract adjustment
        (
            div0null((dm.part_a_risk_adjustment_monthly_rate * dm.part_a_risk_score), dm.num_months_part_a)
            + div0null((dm.part_b_risk_adjustment_monthly_rate * dm.part_b_risk_score), dm.num_months_part_b)
            - div0null(dm.rebate_for_part_d_supplemental_benefits_part_a, dm.num_months_part_a)
            - div0null(dm.rebate_for_part_d_supplemental_benefits_part_b, dm.num_months_part_b)
            - 10.00
        ) * 0.86 as net_payment_amount,

        -- Risk data (use Part A or Part B score, whichever is non-zero)
        coalesce(nullif(dm.part_a_risk_score, 0), nullif(dm.part_b_risk_score, 0)) as raf_score,
        dm.part_d_risk_score as part_d_raf_score,
        dm.raf_type_code,

        -- Adjustment metadata
        dm.adjustment_reason_code::varchar as adjustment_reason_code,
        null::varchar as current_retro_indicator,

        -- Source tracking
        dm.src_file_name,
        dm.src_file_date,
        dm.source,

        -- Deduplication rank (latest file per cap_period + process_month combo)
        dense_rank() over (
            partition by dm.medicare_beneficiary_id, dd.date_day, dm.payment_date
            order by dm.run_date desc, dm.src_file_date desc
        ) as file_rank

    from dw_dev.dev_jkizer_staging.stg_devoted_mmr dm
    left join dw_dev.dev_jkizer.dim_date dd
        on dd.date_day between dm.adjustment_start_date and dm.adjustment_end_date
        and dd.is_bom = 1
    where dm.adjustment_start_date is not null
      and dm.adjustment_end_date is not null
      and dm.payment_date is not null

), wellcare_mmr as (
    -- Wellcare also has date ranges that need to be expanded into individual months
    -- Revenue calculation matches fct_mmr_month_wellcare.sql
    select
        -- Identifiers
        dm.medicare_beneficiary_id,
        null::varchar as member_id,
        null::varchar as gmpi_id,
        null::varchar as subscriber_id,

        -- Time dimensions (expand date range into individual months)
        dd.date_day as cap_period_month,
        date_trunc('month', dm.payment_date)::date as process_month,

        -- Payment data: distribute payment across months, subtract rebates, apply contract adjustment
        (
            (dm.total_ma_payment_amt / nullif(dm.num_months_part_a, 0))
            - (
                (abs(dm.partd_sup_ben_parta_rebate_amt) + abs(dm.partd_sup_ben_partb_rebate_amt)
                 + abs(dm.part_d_basic_premium) + abs(dm.part_d_direct_subsidy_amount))
                / nullif(dm.num_months_part_a, 0)
            )
        ) * 0.845 as net_payment_amount,

        -- Risk data (use Part A or Part B score, whichever is non-zero)
        coalesce(nullif(dm.risk_adjustor_factor_a, 0), nullif(dm.risk_adjustor_factor_b, 0)) as raf_score,
        null::float as part_d_raf_score,
        dm.raf_type_code,

        -- Adjustment metadata
        dm.adjustment_reason_code::varchar as adjustment_reason_code,
        null::varchar as current_retro_indicator,

        -- Source tracking
        dm.src_file_name,
        dm.src_file_date,
        dm.source,

        -- Deduplication rank (latest file per cap_period + process_month combo)
        dense_rank() over (
            partition by dm.medicare_beneficiary_id, dd.date_day, dm.payment_date
            order by dm.run_date desc, dm.src_file_date desc
        ) as file_rank

    from dw_dev.dev_jkizer_staging.stg_wellcare_mmr dm
    left join dw_dev.dev_jkizer.dim_date dd
        on dd.date_day between dm.adjustment_start_date and dm.adjustment_end_date
        and dd.is_bom = 1
    where dm.adjustment_start_date is not null
      and dm.adjustment_end_date is not null
      and dm.payment_date is not null

), combined as (
    select * from wellmed_mmr where file_rank = 1
    union all
    select * from united_mmr where file_rank = 1
    union all
    select * from devoted_mmr where file_rank = 1
    union all
    select * from wellcare_mmr where file_rank = 1
), with_patient_link as (
    -- Add suvida_id via patient linking (LEFT JOIN preserves unmatched records)
    select
        c.*,
        coalesce(
            siw_gmpi.suvida_id,
            siw_mbi.suvida_id,
            siw_member.suvida_id
        ) as suvida_id
    from combined c
    -- WellMed: Join via gmpi_id (matches fct_mmr_month_wellmed pattern)
    left join dw_dev.dev_jkizer.dim_assignment_patient dap_gmpi
        on c.gmpi_id = dap_gmpi.gmpi_id
        and c.source = dap_gmpi.source
        and dap_gmpi.patient_report_index = 1
    left join dw_dev.dev_jkizer.suvida_id_walk siw_gmpi
        on dap_gmpi.member_id = siw_gmpi.member_id
        and dap_gmpi.source = siw_gmpi.source
    -- Devoted/Wellcare: Join via MBI
    left join dw_dev.dev_jkizer.dim_assignment_patient dap_mbi
        on c.medicare_beneficiary_id = dap_mbi.medicare_beneficiary_id
        and c.source = dap_mbi.source
        and c.gmpi_id is null  -- Only for non-WellMed payers
        and dap_mbi.patient_report_index = 1
    left join dw_dev.dev_jkizer.suvida_id_walk siw_mbi
        on dap_mbi.member_id = siw_mbi.member_id
        and dap_mbi.source = siw_mbi.source
    -- United: Join via member_id directly to suvida_id_walk
    left join dw_dev.dev_jkizer.suvida_id_walk siw_member
        on c.member_id = siw_member.member_id
        and c.source = siw_member.source
        and c.gmpi_id is null  -- Only for non-WellMed payers
    where coalesce(
        siw_gmpi.suvida_id,
        siw_mbi.suvida_id,
        siw_member.suvida_id
    ) is not null
)

select
    -- Patient identifier (from linking, may be NULL for unmatched records)
    suvida_id,

    -- Payer identifiers
    medicare_beneficiary_id,
    member_id,
    gmpi_id,
    subscriber_id,

    -- Time dimensions
    cap_period_month,
    process_month,

    -- Payment data
    net_payment_amount,

    -- Risk data
    raf_score,
    part_d_raf_score,
    raf_type_code,

    -- Adjustment metadata
    adjustment_reason_code,
    current_retro_indicator,

    -- Source tracking
    src_file_name,
    src_file_date,
    source

from with_patient_link
-- Deduplicate to ensure one row per grain (patient link joins can cause fan-out)
qualify row_number() over (
    partition by
        suvida_id,
        cap_period_month,
        process_month,
        source, 
        net_payment_amount
    order by suvida_id nulls last, src_file_date desc
) = 1
  );

