select 
    cast(hcc.measure_year as int) as measure_year,
    hcc.suvida_id, 
    ps.elation_id,
    ps.first_name,
    ps.last_name,
    ps.birth_date,
    ps.location_name,
    ps.provider_name,
    ps.num_pcp_visits_ytd_group,
    ps.next_pcp_appt_date,
    'documentation' as measure_group,
    'redocumentation' as measure_name,
    concat(
        'HCC: ', hcc_category, ' ',
        'Redocumented Date: ', to_varchar(first_closed_date)
    ) as measure_detail,
    sum(iff(is_measure_closed = true, 1, 0)) as measure_numerator,
    count(*) as measure_denominator
from dw_dev.dev_jkizer.patient_hcc_process hcc
inner join dw_dev.dev_jkizer.patient_summary ps 
    on ps.suvida_id = hcc.suvida_id 
where hcc_opportunity_type != 'payer_only' 
and hcc_version = '28'
group by all