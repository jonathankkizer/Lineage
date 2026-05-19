
  
    

create or replace transient table dw_dev.dev_jkizer_staging.stg_united_az_quality_measure
    copy grants
    
    
    as (

with cte_united_quality as (
    select
        case
            when len("PATIENT CARD ID") = 7 then to_varchar("PATIENT CARD ID") || '01'
            when len("PATIENT CARD ID") = 6 then '0' || to_varchar("PATIENT CARD ID") || '01'
            else to_varchar("PATIENT CARD ID")
        end as member_id,
        to_timestamp_ntz(to_date(
            substr(src_file_name, 28, 4) || '-' ||
            substr(src_file_name, 23, 3) || '-' ||
            substr(src_file_name, 26, 2),
            'YYYY-MM-DD'
        )) AS report_date,
        "CARE OPPORTUNITY" as measure_type,
        "CARE OPPORTUNITY STATUS" as measure_status,
        "INCENTIVE PROGRAM" as incentive_program,
        src_file_name,
    from SOURCE_PROD.united.src_united_practice_assist_quality
), united_measure_year as ( -- infer measure year based on visit dates; if unavailable, use year in file name
    select
        src_file_name,
        to_timestamp_ntz(coalesce(min(date_trunc(year, coalesce(try_to_date("LAST SERVICE", 'YYYY-MM-DD'), try_to_date("LAST SERVICE", 'MM/DD/YYYY')))), concat(substr(src_file_name, 28, 4), '-','01','-','01'))) as measure_year
    from SOURCE_PROD.united.src_united_practice_assist_quality
    group by all
), practice_assist_data as (
select
    member_id,
    umy.measure_year,
    svh_qm.quality_measure,
    svh_qm.measure_display_name,
    svh_qm.quality_measure_type,
    svh_qm.measure_weight,
    uq.measure_type as payer_quality_measure,
    iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
    case
       when "measure_status" = 'Closure Confirmed - No action needed at this time' then 'Closed'
       when "measure_status" = 'Open' then 'Open'
       when "measure_status" = 'Return-Action Needed' then 'Open'
       when "measure_status" = 'Chart Submitted; Pending Response' then 'Open'
    end as measure_status,
    iff(incentive_program = 'ACO', concat('ACO Patient', ':', coalesce(measure_status, '')), measure_status) as measure_detail,
    null as value_num,
    null as value_ts,
    null as value_bool,
    null as value_txt,
    iff(incentive_program = 'ACO', 'ACO', 'Non-ACO') as aco_flag,
    report_date,
    'United' as source,
    uq.src_file_name,
    'Practice Assist' as report_type,
from cte_united_quality uq
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
    on uq.measure_type = svh_qm.payer_measure_name
    and svh_qm.payer_name = 'United'
left join united_measure_year umy
    on uq.src_file_name = umy.src_file_name
), pcor_measure_year as (
    select 
        src_file_name, 
        to_timestamp_ntz(date_trunc(year, max(value_ts))) as measure_year
    from SOURCE_PROD.united.src_united_quality_pcor_2025_1 pcor
    where value_ts is not null and lower(replace(replace(key, '\r', ''), '\n', '')) = 'annual care visit date'
    group by all
), pcor_aco_flag as (
    select
        src_file_name,
        "MEMBER ID",
        max(value_txt) as aco_flag,
    from SOURCE_PROD.united.src_united_quality_pcor_2025_1 pcor
    where key ilike '%Incentive Program%'
    group by all
), pcor_data as (
    select
        case
            when len(pcor."MEMBER ID") = 7 then to_varchar(pcor."MEMBER ID") || '01'
            when len(pcor."MEMBER ID") = 6 then '0' || to_varchar(pcor."MEMBER ID") || '01'
            else to_varchar(pcor."MEMBER ID")
        end as member_id,
        pmy.measure_year,
        svh_qm.quality_measure,
        svh_qm.measure_display_name,
        svh_qm.quality_measure_type,
        svh_qm.measure_weight,
        -- Remove both carriage return and line feed
        replace(replace(key, '\r', ''), '\n', '') as payer_quality_measure,
        iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
        case 
            when value_txt in ('-', 'G') then 'Closed'
            when value_txt in ('R', 'X', 'NR', 'Y') then 'Open'
            when svh_qm.quality_measure not in ('Med Adherence - Diabetes', 'Med Adherence - RAS', 'Med Adherence - Statins') 
                and value_num is not null then 'Open' -- open status for non-med adherence w/ numeric value present
            when svh_qm.quality_measure in ('Med Adherence - Diabetes', 'Med Adherence - RAS', 'Med Adherence - Statins')
                and try_cast(REPLACE(value_txt, '%', '') as float) / 100 < .8 then 'Open'
            when svh_qm.quality_measure in ('Med Adherence - Diabetes', 'Med Adherence - RAS', 'Med Adherence - Statins')
            and try_cast(REPLACE(value_txt, '%', '') as float) / 100 >= .8 then 'Closed'
        end as measure_status,
        array_to_string(
            array_construct_compact(value_num, value_ts, value_bool, value_txt),
            ' | '
        ) as measure_detail,
        value_num,
        value_ts,
        value_bool,
        value_txt,
        paf.aco_flag,
        to_timestamp_ntz(try_to_date(
          regexp_replace(pcor.src_file_name, '^(\\d{2})\\s*_\\s*(\\d{4}).*', '\\2-\\1-01')
        )) as report_date,
        'United' as source,
        pcor.src_file_name,
        'PCOR' as report_type,
    from SOURCE_PROD.united.src_united_quality_pcor_2025_1 pcor
    left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
        on lower(pcor.key) = lower(svh_qm.payer_measure_name)
        and svh_qm.payer_name = 'United'
    left join pcor_measure_year pmy 
        on pcor.src_file_name = pmy.src_file_name
    left join pcor_aco_flag paf 
        on pcor.src_file_name = paf.src_file_name
        and pcor."MEMBER ID" = paf."MEMBER ID"
    where pcor.value_txt not in ('S', '1X')
)
select *
from pcor_data
where report_date >= '2025-08-01' -- cutover date
union all
select *
from practice_assist_data
where report_date < '2025-08-01' -- cutover date
    )
;


  