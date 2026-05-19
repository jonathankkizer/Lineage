

/*
    MMR Cap Period by Process Month

    This fact model aggregates MMR data by suvida_id, cap period month, process month,
    and source, enabling analysis of:
    - Retroactive adjustment tracking (how payments for a cap period accumulate over time)
    - Cash flow analysis (revenue received by process month)
    - Payment lag analysis (time between cap period and when payment was processed)

    Grain: suvida_id + cap_period_month + process_month + source

    Note: Only includes records that successfully link to a suvida_id.
    Unmatched records are preserved in intmdt_mmr_period_detail for investigation.
*/

select
    -- Primary identifier
    suvida_id,

    -- Time dimensions
    cap_period_month,
    process_month,
    datediff('month', cap_period_month, process_month) as payment_lag_months,

    -- Payment metrics
    sum(net_payment_amount) as total_payment_amount,
    count(*) as payment_record_count,

    -- Risk data (take max RAF score for this period/process combo)
    max(raf_score) as raf_score,
    max(part_d_raf_score) as part_d_raf_score,
    max(raf_type_code) as raf_type_code,

    -- Adjustment tracking
    listagg(distinct adjustment_reason_code, ', ') within group (order by adjustment_reason_code) as adjustment_reason_codes,
    max(current_retro_indicator) as current_retro_indicator,

    -- Source tracking
    source

from dw_dev.dev_jkizer.intmdt_mmr_period_detail
where suvida_id is not null
group by
    suvida_id,
    cap_period_month,
    process_month,
    source