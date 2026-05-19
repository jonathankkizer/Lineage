with sftp_med_adherence as (
    select distinct
        case
            when len("PATIENT CARD ID") = 7 then to_varchar("PATIENT CARD ID") || '01'
            when len("PATIENT CARD ID") = 6 then '0' || to_varchar("PATIENT CARD ID") || '01'
            else to_varchar("PATIENT CARD ID")
        end as member_id,
        uma."LIS PATIENT" as lis_level,
        uma."Rx Category" as payer_quality_measure,
        "DRUG NAME" as measure_detail,
        "PDC MEASURE LEVEL" as pdc_measure_level,
        "DRUG NAME" as rx_name,
        SUBSTRING("QUANTITY/DS", POSITION('/' IN "QUANTITY/DS") + 1) as last_fill_day_supply,
        "DATE OF LAST REFILL" as last_fill_date,
        "NEXT REFILL DUE" as next_refill_due,
        "1X FILL" as is_single_fill,
        to_varchar(null) as refills_remaining,
        split("PHARMACY NAME/ PHONE", ' / ')[0]::varchar as pharmacy_name,
        "PRESCRIBING PROVIDER" as prescriber_name,
        to_varchar(null) as rx_number,
        to_varchar(null) as ninety_day_opportunity,
        to_varchar("ADR MEASURE LEVEL") as gap_days_remaining,
        to_varchar(null) as member_status,
        to_varchar(null) as prescriber_phone,
        to_varchar(null) as rx_tier,
        to_varchar(null) as first_fill_date,
        to_varchar(null) as number_of_fills,
        split("PHARMACY NAME/ PHONE", ' / ')[1]::varchar as pharmacy_phone,
        to_varchar(null) as pharmacy_address,
        "INCENTIVE PROGRAM" as measure_program,
        "LINE OF BUSINESS" as line_of_business,
        "PROVIDER GROUP NAME" as provider_group_name,
        true as split_mad_by_drug,
        split("DRUG NAME", ' ')[0]::varchar as drug_name_category,
        "COLUMN1" as src_file_name,
        'full_report' as report_type,
        risk as risk_status,
        "ABSOLUTE FAIL DATE" as absolute_fail_date
    from SOURCE_PROD.united.src_united_med_adh_part_d uma
),

airbyte_med_adherence as (
    select distinct
        case
            when len(data:"Patient Card ID"::string) = 7 then data:"Patient Card ID"::string || '01'
            when len(data:"Patient Card ID"::string) = 6 then '0' || data:"Patient Card ID"::string || '01'
            else data:"Patient Card ID"::string
        end as member_id,
        data:"LIS Patient"::string as lis_level,
        data:"Rx Category"::string as payer_quality_measure,
        data:"Drug name"::string as measure_detail,
        data:"PDC Measure Level"::string as pdc_measure_level,
        data:"Drug name"::string as rx_name,
        SUBSTRING(data:"Quantity/DS"::string, POSITION('/' IN data:"Quantity/DS"::string) + 1) as last_fill_day_supply,
        data:"Date of last refill"::string as last_fill_date,
        data:"Next Refill Due"::string as next_refill_due,
        data:"1x Fill"::string as is_single_fill,
        to_varchar(null) as refills_remaining,
        split(data:"Pharmacy Name/ Phone"::string, ' / ')[0]::varchar as pharmacy_name,
        data:"Prescribing Provider"::string as prescriber_name,
        to_varchar(null) as rx_number,
        to_varchar(null) as ninety_day_opportunity,
        to_varchar(data:"ADR Measure Level"::string) as gap_days_remaining,
        to_varchar(null) as member_status,
        to_varchar(null) as prescriber_phone,
        to_varchar(null) as rx_tier,
        to_varchar(null) as first_fill_date,
        to_varchar(null) as number_of_fills,
        split(data:"Pharmacy Name/ Phone"::string, ' / ')[1]::varchar as pharmacy_phone,
        to_varchar(null) as pharmacy_address,
        data:"Incentive Program"::string as measure_program,
        data:"Line of Business"::string as line_of_business,
        data:"Provider Group Name"::string as provider_group_name,
        true as split_mad_by_drug,
        split(data:"Drug name"::string, ' ')[0]::varchar as drug_name_category,
        replace(replace(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '_Patient RX Adherence Roster.parquet', '.xlsx') , '_Member Gaps in Care.parquet', '.xlsx') as src_file_name,
        'full_report' as report_type,
        data:"Risk"::string as risk_status,
        try_to_date(data:"Absolute Fail Date"::string) as absolute_fail_date
    from airbyte_source_prod.united_az.quality_med_adherence uma
),

combined as (
    select 
        *
    from sftp_med_adherence
    union all
    select 
        *
    from airbyte_med_adherence
)

select
    combined.member_id,
    svh_qm.quality_measure,
    svh_qm.quality_measure_type,
    svh_qm.measure_weight,
    combined.lis_level,
    combined.payer_quality_measure,
    iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
    combined.measure_detail,
    case
        when svh_qm.quality_measure in ('Statin Therapy for Cardiovascular Disease', 'Statin Use in Persons with Diabetes') and combined.risk_status in ('Y', 'R') then '75'
        when svh_qm.quality_measure in ('Statin Therapy for Cardiovascular Disease', 'Statin Use in Persons with Diabetes') and combined.risk_status in ('G') then '100'
        else REGEXP_SUBSTR(combined.pdc_measure_level, '[0-9]+')
    end as perc_days_covered,
    combined.rx_name,
    combined.last_fill_day_supply,
    combined.last_fill_date,
    combined.next_refill_due,
    combined.is_single_fill,
    combined.refills_remaining,
    combined.pharmacy_name,
    combined.prescriber_name,
    combined.rx_number,
    combined.ninety_day_opportunity,
    combined.gap_days_remaining,
    combined.member_status,
    combined.prescriber_phone,
    combined.rx_tier,
    combined.first_fill_date,
    combined.number_of_fills,
    combined.pharmacy_phone,
    combined.pharmacy_address,
    combined.measure_program,
    combined.line_of_business,
    combined.provider_group_name,
    combined.split_mad_by_drug,
    combined.drug_name_category,
    to_date(left(split(src_file_name, ' ')[4]::varchar, 8), 'MMDDYYYY') as report_date,
    combined.src_file_name,
    combined.report_type,
    combined.risk_status,
    combined.absolute_fail_date,
from combined
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
    on combined.payer_quality_measure = svh_qm.payer_measure_name
    and svh_qm.payer_name = 'United'