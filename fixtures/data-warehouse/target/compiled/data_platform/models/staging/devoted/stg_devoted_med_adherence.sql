

with src as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        data,
        _ab_source_file_url
    from airbyte_source_prod.devoted.quality_med_adherence
    
        where _airbyte_extracted_at > (
            select coalesce(max(_airbyte_extracted_at), '1900-01-01')
            from dw_dev.dev_jkizer_staging.stg_devoted_med_adherence
        )
    
),
devoted_med_adh as (
    select
        s._airbyte_raw_id,
        s._airbyte_extracted_at,

        s.data:"PatientID"::string as member_id,
        coalesce(
            s.data:"Category"::string,
            s.data:"MeasureName"::string
        ) as measure_type,
        s.data:"LastFilledMedication"::string as measure_detail,
        case 
            when try_to_number(s.data:"NumberOfFills"::string) <= 1 then 1
            else 0
        end as is_single_fill,
        s.data:"LastFilledMedication"::string as rx_name,
        try_to_number(s.data:"LastFillRXNumber"::string) as rx_number,
        try_to_number(s.data:"PDC"::string) as perc_days_covered,
        case 
            when s.data:"NeedsExtendedDaySupply"::string = 'N' then 0
            when s.data:"NeedsExtendedDaySupply"::string = 'Y' then 1
            else 0 
        end as ninety_day_opportunity,
        try_to_number(s.data:"DaysUntilGNA"::string) as gap_days_remaining,
        s.data:"MemberStatus"::string as member_status,
        try_to_number(s.data:"LISLEVEL"::string) as lis_level,
        s.data:"PrescriberName"::string as prescriber_name,
        s.data:"PrescriberPhoneNumber"::string as prescriber_phone,
        try_to_date(s.data:"LastFillDate"::string) as last_fill_date,
        try_to_number(s.data:"LastFillDaysSupply"::string) as last_fill_day_supply,
        try_to_date(s.data:"NextFillDueDate"::string) as next_refill_due,
        try_to_number(s.data:"RefillsLeft"::string) as refills_remaining,
        s.data:"LastFillTier"::string as rx_tier,
        try_to_date(s.data:"FirstFillDate"::string) as first_fill_date,
        try_to_number(s.data:"NumberOfFills"::string) as number_of_fills,
        s.data:"PharmacyName"::string as pharmacy_name,
        s.data:"PharmacyPhoneNumber"::string as pharmacy_phone,
        s.data:"PharmacyAddress"::string as pharmacy_address,
        try_to_date(s.data:"ReportDate"::string) as report_date,
        date_from_parts(
            try_to_number(s.data:"Measurementyear"::string),
            1,
            1
        ) as measure_year,
        split(
            s._ab_source_file_url,
            '/'
        )[array_size(split(s._ab_source_file_url, '/')) - 1]::varchar as src_file_name,
        null as claim_reversal
    from src s
)
select
    dma.* exclude (measure_type), 
    svh_qm.quality_measure,
    svh_qm.quality_measure_type,
    svh_qm.measure_weight,
    dma.measure_type as payer_quality_measure,
    iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
    'full_report' as report_type
from devoted_med_adh dma
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
    on dma.measure_type = svh_qm.payer_measure_name
    and svh_qm.payer_name = 'Devoted'