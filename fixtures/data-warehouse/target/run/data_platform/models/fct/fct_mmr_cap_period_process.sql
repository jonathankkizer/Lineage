
  create or replace   view dw_dev.dev_jkizer.fct_mmr_cap_period_process
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$Suvida patient identifier (required - records without suvida_id are excluded)$$, 
  
    "CAP_PERIOD_MONTH" COMMENT $$The month the member was enrolled/capitated for (the month being paid for)$$, 
  
    "PROCESS_MONTH" COMMENT $$The month CMS processed the payment (when payment was actually made)$$, 
  
    "PAYMENT_LAG_MONTHS" COMMENT $$Number of months between cap period and process month (0 = current, >0 = retroactive)$$, 
  
    "TOTAL_PAYMENT_AMOUNT" COMMENT $$Total net payment amount for this cap period / process month combination$$, 
  
    "PAYMENT_RECORD_COUNT" COMMENT $$Number of payment records aggregated$$, 
  
    "RAF_SCORE" COMMENT $$Maximum Risk Adjustment Factor score (Part C) for this period$$, 
  
    "PART_D_RAF_SCORE" COMMENT $$Maximum Part D Risk Adjustment Factor score for this period$$, 
  
    "RAF_TYPE_CODE" COMMENT $$RAF type code indicating the risk model used$$, 
  
    "ADJUSTMENT_REASON_CODES" COMMENT $$Comma-separated list of distinct CMS adjustment reason codes$$, 
  
    "CURRENT_RETRO_INDICATOR" COMMENT $$Indicates if payment is current (C) or retroactive (R)$$, 
  
    "SOURCE" COMMENT $$Payer source (UHG/Wellmed, United, Devoted, Wellcare/Centene)$$
  
)

  copy grants
  
  
  as (
    

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
  );

