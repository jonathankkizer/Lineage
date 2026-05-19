

with devoted_measures as (
    select 
        data:PatientID::varchar as member_id,
        to_timestamp_ntz(date_from_parts(data:MeasurementYear::varchar, '01', '01')) as measure_year,
        data:MeasureName::varchar as measure_type,
        to_varchar(null) as measure_type_description,
        data:Numerator::numeric as source_numerator,
        data:Denominator::numeric as source_denominator,
        iff(
            (data:MeasureCompliance::numeric < data:MemberWeight::numeric) or (data:Numerator::numeric = 0 and data:Denominator::numeric = 1), 
            'OPEN', 
            'CLOSED'
        ) as measure_status,
        to_varchar(null) as measure_detail,
        to_timestamp_ntz(data:ReportDate) as report_date,
        split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
        data as data_variant,
    from airbyte_source_prod.devoted.quality_part_c
)
select 
    member_id,
    measure_year,
    svh_qm.quality_measure,
    svh_qm.measure_display_name,
    svh_qm.quality_measure_type,
    svh_qm.measure_weight,
    dm.measure_type as payer_quality_measure,
    iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
    measure_status,
    measure_detail,
    report_date,	
    'Devoted' as source,
    src_file_name,
    source_numerator,
    source_denominator,
    data_variant,
from devoted_measures dm 
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
    on dm.measure_type = svh_qm.payer_measure_name
    and svh_qm.payer_name = 'Devoted'