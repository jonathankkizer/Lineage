
  
    

create or replace transient table dw_dev.dev_jkizer.revenue_cycle_candid_payer_contract
    copy grants
    
    
    as (with candid_health_claims as (

    select * from dw_dev.dev_jkizer.fct_candid_health_claims

),

member_months as (

    select
        *,
        replace(member_id, '-', '') as member_id_no_dashes,
        split_part(member_id, '-', 1) as member_id_prefix
    from dw_dev.dev_jkizer.patient_member_month

),

final as (

    select
        candid_health_claims.month_of_service,
        date_trunc(month, candid_health_claims.latest_check_date) as payment_month,
        candid_health_claims.latest_check_number as check_number,
        candid_health_claims.primary_insurance_suvida_id,
        candid_health_claims.claim_id,
        candid_health_claims.primary_insurance_payer_name_clean,
        candid_health_claims.primary_insurance_plan_name,
        candid_health_claims.service_facility_address,
        case
            when coalesce(member_months_exact.has_financial_membership, member_months_prefix.has_financial_membership) = 1  or coalesce(member_months_exact.has_assignment, member_months_prefix.has_assignment) = 1 then '1'
            when coalesce(member_months_exact.has_financial_membership, member_months_prefix.has_financial_membership) = 0 and coalesce(member_months_exact.has_assignment, member_months_prefix.has_assignment) = 0 then '0'
            else 'Default'
        end as at_risk_flag,
        coalesce(member_months_exact.assignment_payer_contract, member_months_prefix.assignment_payer_contract, 'No Payer') as contract_payer,
        sum(coalesce(candid_health_claims.sum_charge_amount_dollars, 0)) as sum_charge_amount_dollars,
        sum(coalesce(candid_health_claims.sum_paid_amount_dollars, 0)) as sum_paid_amount_dollars
    from candid_health_claims
    left join member_months as member_months_exact
        on candid_health_claims.primary_insurance_member_id = member_months_exact.member_id_no_dashes
        and candid_health_claims.month_of_service = member_months_exact.member_month
    left join member_months as member_months_prefix
        on candid_health_claims.primary_insurance_member_id = member_months_prefix.member_id_prefix
        and candid_health_claims.month_of_service = member_months_prefix.member_month
        and member_months_exact.member_id is null
    group by all
)

select * from final
    )
;


  