
  
    

create or replace transient table dw_dev.dev_jkizer.patient_member_month
    copy grants
    
    
    as (/*
    SUVIDA UNIFIED MEMBER MONTH MODEL

    Purpose: Creates a single source of truth for patient membership by combining:
    - Assignment data (from payers, indicates clinical attribution)
    - Financial membership (from member-level P&L statements, indicates premium revenue)

    Key Business Rule - 3-Month Switching Logic:
    - Recent months (last 3): Use assignment data as the primary membership indicator
      Rationale: Assignment data is more timely and reflects current clinical responsibility
    - Historical months (>3 months old): Use financial membership as the primary indicator
      Rationale: Financial data is more complete and stable for revenue/membership analysis

    This switching logic is implemented in the has_active_membership field and is used
    consistently across ADK metrics and membership reporting.
*/

with assignment_data as (
    select
        suvida_id,
        date_month,
        assignment_member_id,
        assignment_source,
        assignment_payer_parent,
        assignment_payer_name,
        assignment_payer_contract,
        assignment_provider_name,
        assignment_location_name,
        source_lob as assignment_source_lob,
        plan_name as assignment_plan_name,
        plan_network_type as assignment_plan_network_type,
        plan_program_type as assignment_plan_program_type,
        plan_network_program_type as assignment_plan_network_program_type,
    from dw_dev.dev_jkizer.patient_assignment
    where assignment_month_ind = 1  -- Only include months where patient was assigned
), financial_data as (
    select
        suvida_id,
        member_id,
        financial_member_month,
        financial_source,
        financial_provider_name,
        financial_location_name,
        part_c_net_premium,
        part_d_net_premium,
        part_d_expense,
        source_lob as financial_source_lob,
        pbp_code,
        plan_name as financial_plan_name,
        plan_network_type as financial_plan_network_type,
        plan_program_type as financial_plan_program_type,
        plan_network_program_type as financial_plan_network_program_type,
    from dw_dev.dev_jkizer.patient_financial_membership
    where is_financial_membership_month = true  -- Only include active financial membership months
), suvida_join as (
    /*
        Primary Join Strategy: Match on suvida_id + member_month

        This captures the majority of records where we have successfully matched
        patients across both assignment and financial systems using our internal
        Suvida ID. Uses FULL OUTER JOIN to preserve records from both sides.
    */
    select
        coalesce(f.suvida_id, a.suvida_id) as suvida_id,
        coalesce(f.member_id, a.assignment_member_id) as member_id,
        coalesce(f.financial_member_month, a.date_month) as member_month,
        a.assignment_source,
        a.assignment_payer_parent,
        a.assignment_payer_name,
        a.assignment_payer_contract,
        a.assignment_provider_name,
        a.assignment_location_name,
        f.financial_source,
        f.financial_provider_name,
        f.financial_location_name,
        f.part_c_net_premium,
        f.part_d_net_premium,
        f.part_d_expense,
        coalesce(f.financial_source, a.assignment_payer_parent) as payer_parent,
        coalesce(f.financial_source, a.assignment_payer_name) as payer_name,
        coalesce(f.financial_source, a.assignment_payer_contract) as payer_contract,
        coalesce(f.financial_source_lob, a.assignment_source_lob) as source_lob,
        f.pbp_code,
        coalesce(f.financial_plan_name, a.assignment_plan_name) as plan_name,
        coalesce(f.financial_plan_network_type, a.assignment_plan_network_type) as plan_network_type,
        coalesce(f.financial_plan_program_type, a.assignment_plan_program_type) as plan_program_type,
        coalesce(f.financial_plan_network_program_type, a.assignment_plan_network_program_type) as plan_network_program_type,
        case when a.suvida_id is not null then 1 else 0 end as has_assignment,
        case when f.suvida_id is not null then 1 else 0 end as has_financial_membership,
    from financial_data f
    full outer join assignment_data a
        on f.suvida_id = a.suvida_id
        and f.financial_member_month = a.date_month
    where f.suvida_id is not null or a.suvida_id is not null
), member_id_join as (
    /*
        Fallback Join Strategy: Match on member_id + member_month (when financial lacks suvida_id)

        This handles edge cases where financial membership data hasn't been matched to a
        suvida_id yet. We can still link these records using the payer's member_id.
        Note: These records will have a suvida_id from the assignment side only.
    */
    select
        a.suvida_id,
        coalesce(f.member_id, a.assignment_member_id) as member_id,
        coalesce(f.financial_member_month, a.date_month) as member_month,
        a.assignment_source,
        a.assignment_payer_parent,
        a.assignment_payer_name,
        a.assignment_payer_contract,
        a.assignment_provider_name,
        a.assignment_location_name,
        f.financial_source,
        f.financial_provider_name,
        f.financial_location_name,
        f.part_c_net_premium,
        f.part_d_net_premium,
        f.part_d_expense,
        coalesce(f.financial_source, a.assignment_payer_parent) as payer_parent,
        coalesce(f.financial_source, a.assignment_payer_name) as payer_name,
        coalesce(f.financial_source, a.assignment_payer_contract) as payer_contract,
        coalesce(f.financial_source_lob, a.assignment_source_lob) as source_lob,
        f.pbp_code,
        coalesce(f.financial_plan_name, a.assignment_plan_name) as plan_name,
        coalesce(f.financial_plan_network_type, a.assignment_plan_network_type) as plan_network_type,
        coalesce(f.financial_plan_program_type, a.assignment_plan_program_type) as plan_program_type,
        coalesce(f.financial_plan_network_program_type, a.assignment_plan_network_program_type) as plan_network_program_type,
        case when a.suvida_id is not null then 1 else 0 end as has_assignment,
        case when f.member_id is not null then 1 else 0 end as has_financial_membership,
    from financial_data f
    full outer join assignment_data a
        on f.member_id = a.assignment_member_id
        and f.financial_member_month = a.date_month
        and f.suvida_id is null -- only use member_id join when financial data has no suvida_id
    where f.suvida_id is null and f.member_id is not null -- only include records with a financial record that has null suvida_id
), combined as (
    select * from suvida_join
    union all
    select * from member_id_join
), suvida_id_flag as (
    /*
        Duplicate Detection

        Identifies suvida_id + member_month combinations that appear multiple times in the
        unified dataset. This shouldn't happen with proper join logic but can occur due to:
        - Multiple member_ids for the same patient in the same month
        - Data quality issues in source systems

        Action: Records flagged as duplicates should be investigated and deduplicated in
        upstream models (patient_assignment or patient_financial_membership).
    */
    select
        suvida_id,
        member_month,
        true as check_suvida_id_flag
    from combined
    group by all
    having count(*) > 1
)
select
    md5(cast(coalesce(cast(c.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(c.member_month as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_month_skey,
    c.suvida_id,
    member_id,
    c.member_month,
    monthname(c.member_month) as month_name,
    assignment_source,
    assignment_payer_parent,
    assignment_payer_name,
    assignment_payer_contract,
    assignment_provider_name,
    assignment_location_name,
    financial_source,
    financial_provider_name,
    financial_location_name,
    part_c_net_premium,
    part_d_net_premium,
    part_d_expense,
    source_lob,
    pbp_code,
    payer_parent,
    payer_name,
    payer_contract,
    plan_name,
    plan_network_type,
    plan_program_type,
    plan_network_program_type,
    has_assignment,
    has_financial_membership,
    case
        when has_assignment = 1 and has_financial_membership = 1 then 'both'
        when has_assignment = 1 and has_financial_membership = 0 then 'assignment_only'
        when has_assignment = 0 and has_financial_membership = 1 then 'financial_only'
    end as membership_type,
    /*
        CRITICAL FIELD: has_active_membership

        This implements Suvida's standard 3-month switching logic:
        - For months in the last 3 months: Uses assignment data (has_assignment)
        - For months older than 3 months: Uses financial membership (has_financial_membership)

        This field should be used as the default membership filter for all standard
        reporting, ADK calculations, and membership counts.
    */
    case
        when c.member_month >= dateadd(month, -3, date_trunc(month, current_date())) then has_assignment
        else has_financial_membership
    end as has_active_membership,
    sif.check_suvida_id_flag,
from combined c
left join suvida_id_flag sif
    on c.suvida_id = sif.suvida_id
    and c.member_month = sif.member_month
    )
;


  