with wellcare_gaps as (
    select
        to_varchar(g.plan_member_id) as member_id,
        'Wellcare/Centene' as measure_source,
        dos_year as measure_year,
        replace(split("DIAGNOSIS/OTHER INFO", ' ')[0]::varchar, '.', '') as icd_10_code,
        iff(assessment_status = 'Unassessed', 'open', 'closed') as measure_status,
        "DIAGNOSIS/OTHER INFO" as measure_detail,
        date(replace(split(src_file_name, ' ')[5]::varchar, '.xlsx', ''), 'MM.YYYY') as report_date,
        src_file_name,
        '28'::varchar as hcc_version,
    from source_prod.wellcare.src_wellcare_risk_adjustment_gaps_2025_1 g
)
select
    wg.*,
    hcc.hcc as hcc_category,
from wellcare_gaps wg
inner join dw_dev.dev_jkizer_staging.stg_icd_hcc_map icdhcc
	on wg.icd_10_code = icdhcc.icd_10_code
	and icdhcc.payment_year = 2024
inner join dw_dev.dev_jkizer_staging.stg_hcc_reference hcc
	on concat('HCC', icdhcc.hcc_v28) = hcc.hcc
	and hcc.hcc_version = wg.hcc_version
where hcc_v28 is not null