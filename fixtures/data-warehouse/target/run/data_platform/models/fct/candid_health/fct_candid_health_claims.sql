
  
    

create or replace transient table dw_dev.dev_jkizer.fct_candid_health_claims
    copy grants
    
    
    as (with encounters as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_encounter
    where is_deleted = false

),

transactions as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_transaction
    where voided_by_transaction_id is null
        and voids_transaction_id is null

),

payment_details as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_payment_details

),

informational_adjustment_details as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_informational_adjustment_details

),

financial_summary as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_financial_summary

),

service_lines as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_service_line
    where is_deleted = false

),

service_line_projected_financials as (

    select * from dw_dev.dev_jkizer_staging.stg_candid_health_export_service_line_projected_financials

),

suvida_id_walk as (

    select
        *,
        replace(member_id, '-', '') as member_id_no_dashes,
        split_part(member_id, '-', 1) as member_id_prefix
    from dw_dev.dev_jkizer.suvida_id_walk

),

-- =============================================================================
-- ENCOUNTER BASE
-- =============================================================================

encounters_base as (

    select
        encounter_id,
        claim_id,
        external_id as encounter_external_id,
        date_of_service,
        dateadd(day, -mod(dayofweek(date_of_service), 7), date_of_service) as week_of_service,
        date_trunc('month', date_of_service) as month_of_service,
        updated_at as claim_updated_at,

        -- Primary insurance
        subscriber_primary_insurance_card_payer_name as primary_insurance_payer_name,
        subscriber_primary_insurance_card_payer_name as primary_insurance_payer_name_clean,
        subscriber_primary_insurance_card_payer_id as primary_insurance_payer_id,
        subscriber_primary_insurance_card_insurance_type as primary_insurance_insurance_type,
        subscriber_primary_insurance_card_plan_name as primary_insurance_plan_name,
        subscriber_primary_insurance_card_plan_type as primary_insurance_plan_type,
        subscriber_primary_insurance_card_member_id as primary_insurance_member_id,
        subscriber_primary_insurance_card_group_number as primary_insurance_group_number,
        subscriber_primary_patient_relationship_to_subscriber_code as patient_relationship_to_primary_subscriber_code,

        -- Secondary insurance
        subscriber_secondary_insurance_card_payer_name as secondary_insurance_payer_name,
        subscriber_secondary_insurance_card_payer_id as secondary_insurance_payer_id,
        subscriber_secondary_insurance_card_member_id as secondary_insurance_member_id,
        subscriber_secondary_insurance_card_plan_name as secondary_insurance_plan_name,
        subscriber_secondary_insurance_card_insurance_type as secondary_insurance_insurance_type,
        subscriber_secondary_insurance_card_plan_type as secondary_insurance_plan_type,
        subscriber_secondary_insurance_card_group_number as secondary_insurance_group_number,
        subscriber_secondary_patient_relationship_to_subscriber_code as patient_relationship_to_secondary_subscriber_code,

        -- Appointment & billing
        appointment_type,
        responsible_party,
        billable_status,
        claim_status,
        place_of_service_code,
        place_of_service_code_as_submitted as encounter_place_of_service_code_as_submitted,

        -- Patient
        patient_external_id,
        claim_patient_control_number as patient_control_number,
        patient_first_name as first_name,
        patient_last_name as last_name,
        patient_date_of_birth as date_of_birth,
        patient_address_state as state,
        patient_reason_for_visit_codes,

        -- Diagnosis codes
        diagnosis_codes,

        -- Dates
        created_at::date as date_received,
        dateadd(day, -mod(dayofweek(created_at), 7), created_at::date) as week_received,
        date_first_submitted,
        date_last_submitted,
        admission_date,
        discharge_date,
        updated_at::date as latest_action_date,

        -- Lag calculations
        datediff('day', date_of_service, created_at::date) as submit_to_candid_lag_days,
        floor(datediff('day', date_of_service, created_at::date) / 7) + 1 as submit_to_candid_lag_weeks_rounded,

        -- Providers
        rendering_provider_last_name,
        rendering_provider_npi,
        rendering_provider_taxonomy_code,
        billing_provider_organization_name,
        billing_provider_npi,
        nullif(trim(concat_ws(' ', referring_provider_first_name, referring_provider_last_name)), '') as referring_provider_name,
        nullif(trim(concat_ws(' ', ordering_provider_first_name, ordering_provider_last_name)), '') as ordering_provider_name,

        -- Service facility
        service_facility_organization_name as service_facility_name,
        nullif(
            array_to_string(
                array_compact(
                    array_construct(
                        nullif(service_facility_address_address_1, ''),
                        nullif(service_facility_address_address_2, ''),
                        nullif(service_facility_address_city, ''),
                        nullif(service_facility_address_state, ''),
                        case
                            when nullif(service_facility_address_zip_plus_four_code, '') is not null
                                then coalesce(service_facility_address_zip_code, '') || '-' || service_facility_address_zip_plus_four_code
                            else nullif(service_facility_address_zip_code, '')
                        end
                    )
                ),
                ', '
            ),
            ''
        ) as service_facility_address,

        -- Organization
        organization_id,

        -- Claim details
        claim_form_type,
        type_of_bill,
        discharge_status,
        admission_source_code,
        admission_type_code,
        prior_authorization_number,
        claim_clia_number as clia_number,

        -- Clinical
        vitals_hemoglobin_gdl as hemoglobin_gdl,
        vitals_hematocrit_pct as hematocrit_pct,
        tags,

        -- AR & contracting
        claim_adjudicated_network_status as adjudicated_network_status

    from encounters

),

-- =============================================================================
-- TRANSACTION TOTALS
-- Transaction types: CHARGE, PAYMENT, ADJUSTMENT, BALANCE_TRANSFER
-- Counter party types: PAYER, PATIENT
-- =============================================================================

charge_totals as (

    select
        encounter_id,
        sum(amount) as sum_charge_amount_dollars
    from transactions
    where transaction_type = 'CHARGE'
    group by all

),

payer_payment_totals as (

    select
        transactions.encounter_id,
        max(payment_details.check_date) as latest_check_date,
        max_by(payment_details.external_payment_id, payment_details.check_date) as latest_check_number,
        max(payment_details.payment_posted_date) as latest_era_posted_date,
        sum(transactions.amount) * (-1) as sum_paid_amount_dollars
    from transactions
    left join payment_details
        on transactions.transaction_id = payment_details.transaction_id
    where transactions.transaction_type = 'PAYMENT'
        and transactions.counter_party_type = 'PAYER'
    group by all

),

patient_payment_totals as (

    select
        encounter_id,
        sum(amount) as sum_patient_payments_dollars,
        max(transaction_timestamp) as most_recent_patient_payment_date
    from transactions
    where transaction_type = 'PAYMENT'
        and counter_party_type = 'PATIENT'
    group by all

),

payer_adjustment_totals as (

    select
        encounter_id,
        sum(amount) as sum_payer_adjustment_dollars
    from transactions
    where transaction_type = 'ADJUSTMENT'
        and counter_party_type = 'PAYER'
    group by all

),

patient_adjustment_totals as (

    select
        encounter_id,
        sum(amount) * (-1) as sum_patient_adjustment_dollars
    from transactions
    where transaction_type = 'ADJUSTMENT'
        and counter_party_type = 'PATIENT'
    group by all

),

-- =============================================================================
-- INFORMATIONAL CHECK TOTALS
-- Fallback for check date/number when no payment transactions exist
-- =============================================================================

informational_check_totals as (

    select
        encounter_id,
        max(check_date) as latest_check_date,
        max_by(external_payment_id, check_date) as latest_check_number,
        max(payment_posted_date) as latest_era_posted_date
    from informational_adjustment_details
    where check_date is not null
    group by all

),

-- =============================================================================
-- FINANCIAL SUMMARY
-- Source of truth for allowed amounts, patient responsibility breakdowns,
-- insurance adjustments/write-offs, and balance amounts
-- =============================================================================

financial_summary_totals as (

    select
        encounter_id,
        sum(allowed_amount) as sum_allowed_amount_dollars,
        sum(patient_responsibility) as sum_patient_responsibility_dollars,
        sum(copay_amount) as sum_copay_dollars,
        sum(deductible_amount) as sum_deductible_dollars,
        sum(coinsurance_amount) as sum_coinsurance_dollars,
        sum(insurance_adjustment_amount) as sum_insurance_adjustment_dollars,
        sum(insurance_write_off_amount) as sum_insurance_write_off_dollars,
        sum(claim_balance_amount) as sum_claim_balance_dollars,
        sum(patient_balance_amount) as sum_patient_balance_dollars
    from financial_summary
    group by all

),

-- =============================================================================
-- SERVICE LINE PROCEDURE CODES
-- Aggregated from service_lines to encounter level
-- =============================================================================

service_line_procedure_codes as (

    select
        encounter_id,
        array_agg(distinct procedure_code) within group (order by procedure_code) as procedure_codes,
        min(created_at)::date as date_first_coded
    from service_lines
    group by all

),

-- =============================================================================
-- SERVICE LINE PROJECTED FINANCIALS
-- Joined through service_lines to get encounter_id
-- =============================================================================

projected_financials_totals as (

    select
        service_lines.encounter_id,
        sum(service_line_projected_financials.expected_allowed_amount_dollars) as sum_expected_allowed_amount_dollars,
        sum(service_line_projected_financials.expected_adjustment_amount_dollars) as sum_expected_adjustment_amount_dollars
    from service_line_projected_financials
    inner join service_lines
        on service_line_projected_financials.service_line_id = service_lines.service_line_id
    group by all

),

-- =============================================================================
-- DENIAL / REMARK / ADJUSTMENT REASON CODES
-- =============================================================================

denial_reason_codes as (

    select
        encounter_id,
        listagg(distinct carc, ', ') within group (order by carc) as claim_adjustment_reason_codes_agg,
        listagg(distinct remark_codes, ', ') within group (order by remark_codes) as remittance_advice_remark_codes_agg,
        listagg(distinct adjustment_reason_code, ', ') within group (order by adjustment_reason_code) as denial_reasons_agg
    from informational_adjustment_details
    group by all

),

-- =============================================================================
-- FINAL JOIN
-- =============================================================================

final as (

    select
        encounters_base.encounter_id,
        encounters_base.primary_insurance_payer_name,
        encounters_base.primary_insurance_payer_name_clean,
        encounters_base.primary_insurance_payer_id,
        encounters_base.primary_insurance_insurance_type,
        encounters_base.primary_insurance_plan_name,
        encounters_base.primary_insurance_plan_type,
        encounters_base.secondary_insurance_payer_name,
        encounters_base.secondary_insurance_payer_id,
        encounters_base.date_of_service,
        encounters_base.week_of_service,
        encounters_base.month_of_service,
        encounters_base.claim_updated_at,
        encounters_base.appointment_type,
        encounters_base.responsible_party,
        encounters_base.billable_status,
        encounters_base.claim_status,
        encounters_base.encounter_external_id,
        encounters_base.claim_id,
        encounters_base.place_of_service_code,
        encounters_base.encounter_place_of_service_code_as_submitted,
        coalesce(charge_totals.sum_charge_amount_dollars, 0) as sum_charge_amount_dollars,
        coalesce(financial_summary_totals.sum_allowed_amount_dollars, 0) as sum_allowed_amount_dollars,
        coalesce(projected_financials_totals.sum_expected_allowed_amount_dollars, 0) as sum_expected_allowed_amount_dollars,
        coalesce(financial_summary_totals.sum_allowed_amount_dollars, 0) as sum_expected_revenue_dollars,
        coalesce(payer_payment_totals.sum_paid_amount_dollars, 0) as sum_paid_amount_dollars,
        coalesce(financial_summary_totals.sum_patient_responsibility_dollars, 0) as sum_patient_responsibility_dollars,
        coalesce(financial_summary_totals.sum_copay_dollars, 0) as sum_copay_dollars,
        coalesce(financial_summary_totals.sum_deductible_dollars, 0) as sum_deductible_dollars,
        coalesce(financial_summary_totals.sum_coinsurance_dollars, 0) as sum_coinsurance_dollars,
        coalesce(patient_payment_totals.sum_patient_payments_dollars, 0) as sum_patient_payments_dollars,
        coalesce(patient_adjustment_totals.sum_patient_adjustment_dollars, 0) as sum_patient_adjustment_dollars,
        encounters_base.diagnosis_codes,
        service_line_procedure_codes.procedure_codes,
        encounters_base.date_received,
        encounters_base.week_received,
        encounters_base.submit_to_candid_lag_days,
        encounters_base.submit_to_candid_lag_weeks_rounded,
        service_line_procedure_codes.date_first_coded,
        datediff('day', encounters_base.date_received, service_line_procedure_codes.date_first_coded) as coding_lag,
        encounters_base.date_first_submitted,
        encounters_base.date_last_submitted,
        datediff('day', service_line_procedure_codes.date_first_coded, encounters_base.date_first_submitted) as submit_to_payer_lag_days,
        floor(datediff('day', service_line_procedure_codes.date_first_coded, encounters_base.date_first_submitted) / 7) + 1 as submit_to_payer_lag_weeks_rounded,
        encounters_base.rendering_provider_last_name,
        encounters_base.rendering_provider_npi,
        encounters_base.billing_provider_organization_name,
        encounters_base.billing_provider_npi,
        encounters_base.service_facility_address,
        encounters_base.organization_id,
        datediff(
            'day',
            coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service),
            current_date
        ) as days_in_ar,
        case
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 30 then '0-30'
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 60 then '31-60'
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 90 then '61-90'
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 120 then '91-120'
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 180 then '121-180'
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 270 then '181-270'
            when datediff('day', coalesce(encounters_base.date_first_submitted, encounters_base.date_of_service), current_date) <= 360 then '271-360'
            else '360+'
        end as ar_bucket,
        encounters_base.adjudicated_network_status,
        coalesce(payer_payment_totals.latest_check_date, informational_check_totals.latest_check_date) as latest_check_date,
        coalesce(payer_payment_totals.latest_check_number, informational_check_totals.latest_check_number) as latest_check_number,
        denial_reason_codes.claim_adjustment_reason_codes_agg,
        denial_reason_codes.remittance_advice_remark_codes_agg,
        denial_reason_codes.denial_reasons_agg,
        encounters_base.tags,
        encounters_base.patient_control_number,
        encounters_base.patient_external_id,
        coalesce(payer_payment_totals.latest_era_posted_date, informational_check_totals.latest_era_posted_date) as latest_era_posted_date,
        encounters_base.service_facility_name,
        coalesce(suvida_id_walk_exact.suvida_id, suvida_id_walk_prefix.suvida_id) as primary_insurance_suvida_id,
        encounters_base.primary_insurance_member_id,
        encounters_base.secondary_insurance_member_id,
        encounters_base.secondary_insurance_plan_name,
        encounters_base.secondary_insurance_insurance_type,
        encounters_base.secondary_insurance_plan_type,
        encounters_base.latest_action_date,
        encounters_base.admission_date,
        encounters_base.discharge_date,
        encounters_base.prior_authorization_number,
        encounters_base.hemoglobin_gdl,
        encounters_base.hematocrit_pct,
        encounters_base.referring_provider_name,
        encounters_base.ordering_provider_name,
        coalesce(financial_summary_totals.sum_patient_responsibility_dollars, 0)
            - coalesce(financial_summary_totals.sum_copay_dollars, 0)
            - coalesce(financial_summary_totals.sum_deductible_dollars, 0)
            - coalesce(financial_summary_totals.sum_coinsurance_dollars, 0)
        as sum_other_patient_responsibility_dollars,
        encounters_base.primary_insurance_group_number,
        encounters_base.first_name,
        encounters_base.last_name,
        encounters_base.date_of_birth,
        encounters_base.state,
        coalesce(financial_summary_totals.sum_claim_balance_dollars, 0) as gross_accounts_receivable,
        coalesce(projected_financials_totals.sum_expected_adjustment_amount_dollars, 0) as sum_expected_adjustment_amount_dollars,
        coalesce(financial_summary_totals.sum_insurance_adjustment_dollars, 0) as sum_insurance_adjustment_dollars,
        coalesce(financial_summary_totals.sum_insurance_write_off_dollars, 0) as sum_insurance_write_off_dollars,
        encounters_base.patient_relationship_to_primary_subscriber_code,
        encounters_base.secondary_insurance_group_number,
        encounters_base.patient_relationship_to_secondary_subscriber_code,
        encounters_base.rendering_provider_taxonomy_code,
        encounters_base.patient_reason_for_visit_codes,
        encounters_base.admission_source_code,
        encounters_base.admission_type_code,
        encounters_base.claim_form_type,
        encounters_base.type_of_bill,
        encounters_base.discharge_status,
        encounters_base.clia_number,
        patient_payment_totals.most_recent_patient_payment_date
    from encounters_base
    left join charge_totals
        on encounters_base.encounter_id = charge_totals.encounter_id
    left join payer_payment_totals
        on encounters_base.encounter_id = payer_payment_totals.encounter_id
    left join patient_payment_totals
        on encounters_base.encounter_id = patient_payment_totals.encounter_id
    left join payer_adjustment_totals
        on encounters_base.encounter_id = payer_adjustment_totals.encounter_id
    left join patient_adjustment_totals
        on encounters_base.encounter_id = patient_adjustment_totals.encounter_id
    left join informational_check_totals
        on encounters_base.encounter_id = informational_check_totals.encounter_id
    left join financial_summary_totals
        on encounters_base.encounter_id = financial_summary_totals.encounter_id
    left join projected_financials_totals
        on encounters_base.encounter_id = projected_financials_totals.encounter_id
    left join denial_reason_codes
        on encounters_base.encounter_id = denial_reason_codes.encounter_id
    left join service_line_procedure_codes
        on encounters_base.encounter_id = service_line_procedure_codes.encounter_id
    left join suvida_id_walk as suvida_id_walk_exact
        on encounters_base.primary_insurance_member_id = suvida_id_walk_exact.member_id_no_dashes
    left join suvida_id_walk as suvida_id_walk_prefix
        on encounters_base.primary_insurance_member_id = suvida_id_walk_prefix.member_id_prefix
        and suvida_id_walk_exact.member_id is null

)

select * from final
    )
;


  