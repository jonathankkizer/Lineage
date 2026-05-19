
  
    

create or replace transient table dw_dev.dev_jkizer.suvida_id_duplicate_elation_work_list
    copy grants
    
    
    as (with num_accounts as ( -- determine # of accounts from each source can be used to find potential incorrect matches
	select
		siw.suvida_id,
		sum(case when ipi.source = 'Elation' then 1 else 0 end) as num_elation_accounts,
		sum(case when ipi.source = 'Devoted' then 1 else 0 end) as num_devoted_accounts,
		sum(case when ipi.source = 'UHG/Wellmed' then 1 else 0 end) as num_wellmed_accounts,
		sum(case when ipi.source = 'Wellcare/Centene' then 1 else 0 end) as num_wellcare_accounts,
		sum(case when ipi.source = 'Wellcare AZ' then 1 else 0 end) as num_wellcare_az_accounts
	from dw_dev.dev_jkizer.suvida_id_walk siw 
	left join dw_dev.dev_jkizer.int_suvida_id_input ipi
		on siw.member_id = ipi.member_id 
		and siw.source = ipi.source
	group by siw.suvida_id
), suvida_id_conf_score as ( -- get average confidence score per suvida_id later used to rank "most suspect" matches
	select 
		siw.suvida_id,
		avg(sio.confidence_score) as avg_confidence_score
	from dw_dev.dev_jkizer.suvida_id_walk siw 
	left join dw_dev.dev_jkizer_staging.stg_suvida_identifier_output sio 
		on siw.member_id = sio.member_id 
		and siw.source = sio.source 
	group by siw.suvida_id
)
select -- wide list of patient attributes that center directors can use to look up patients in EMR, comment on match/duplication status
	siw.*,
	sics.avg_confidence_score,
	ps.provider_name,
	ipi.first_name,
	ipi.last_name,
	ipi.middle_name,
	ipi.middle_initial,
	ipi.birth_date,
	ipi.age_year,
	ipi.address_line_1,
	ipi.address_line_2,
	ipi.city,
	ipi.state,
	ipi.zip,
	ipi.gender,
	ipi.phone,
	na.num_elation_accounts,
	na.num_devoted_accounts,
	na.num_wellmed_accounts,
	na.num_wellcare_accounts,
	na.num_wellcare_az_accounts
from dw_dev.dev_jkizer.suvida_id_walk siw 
left join dw_dev.dev_jkizer_staging.stg_suvida_identifier_output sio 
	on siw.member_id = sio.member_id 
	and siw.source = sio.source
left join dw_dev.dev_jkizer.int_suvida_id_input ipi
	on siw.member_id = ipi.member_id 
	and siw.source = ipi.source
left join dw_dev.dev_jkizer.patient_summary ps 
	on siw.suvida_id = ps.suvida_id
left join num_accounts na 
	on siw.suvida_id = na.suvida_id
left join suvida_id_conf_score sics 
	on siw.suvida_id = sics.suvida_id
where num_elation_accounts >= 2
and siw.source = 'Elation'
    )
;


  