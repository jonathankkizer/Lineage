
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_measure_count_sandbox
    copy grants
    
    
    as (select distinct
	p.suvida_id,
	coalesce(oqm."count", 0) as num_open_quality_measures,
	coalesce(qm."count", 0) as total_quality_measures,
	coalesce(oao."count", 0) as num_open_attestation_opportunities,
	coalesce(ao."count", 0) as total_attestation_opportunities
from dw_dev.dev_jkizer.int_patient_summary_sandbox p
left join (
	select suvida_id, sum(count) as "count"
	from (
		select suvida_id, count(distinct quality_measure_skey) as "count"
		from dw_dev.dev_jkizer.int_patient_quality_measure_sandbox
		where
            coalesce(current_quality_engine_status, quality_engine_status) = 'Open' and
            year(to_date(measure_year)) = year(sysdate()) and
            is_measure_year_current_report = 1 and
            compas_flag = TRUE and
            is_trc_measure = 0
		group by suvida_id

		union all

		select suvida_id, count(distinct med_adherence_measure_skey) as "count"
		from dw_dev.dev_jkizer.int_patient_med_adherence_sandbox
		where
            coalesce(current_quality_engine_status, quality_engine_status) in ('Open', 'Pending') and
            current_quality_engine_evidence:med_adherence_gap_status in ('Permanently Failed', 'Currently Failing', 'At-Risk') and
            year(to_date(measure_year)) = year(sysdate()) and
            is_measure_year_current_report = 1
		group by suvida_id
	) as open_quality
	group by suvida_id
) as oqm on p.suvida_id = oqm.suvida_id
left join (
	select suvida_id, sum("count") as "count"
	from (
		select suvida_id, count(distinct quality_measure_skey) as "count"
		from dw_dev.dev_jkizer.int_patient_quality_measure_sandbox
		where
            year(to_date(measure_year)) = year(sysdate()) and
            is_measure_year_current_report = 1 and
            compas_flag = TRUE and
            is_trc_measure = 0
		group by suvida_id

		union all

		select suvida_id, count(distinct med_adherence_measure_skey) as "count"
		from dw_dev.dev_jkizer.int_patient_med_adherence_sandbox
		where
            year(to_date(measure_year)) = year(sysdate()) and
            is_measure_year_current_report = 1
		group by suvida_id
	) as total_qualiy
	group by suvida_id
) as qm on p.suvida_id = qm.suvida_id
left join (
	select suvida_id, count(distinct attestation_opportunity_skey) as "count"
	from dw_dev.dev_jkizer.int_patient_attestation_opportunity_sandbox
	where attestation_opportunity_status <> 'closed' and measure_year = year(sysdate())
	group by suvida_id
) as oao on p.suvida_id = oao.suvida_id
left join (
	select suvida_id, count(distinct attestation_opportunity_skey) as "count"
	from dw_dev.dev_jkizer.int_patient_attestation_opportunity_sandbox
	where measure_year = year(sysdate())
	group by suvida_id
) as ao on p.suvida_id = ao.suvida_id
    )
;


  