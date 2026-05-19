
  
    

create or replace transient table dw_dev.dev_jkizer.suvida_id_multiple_cluster_work_list
    copy grants
    
    
    as (with multiple_clusters_one_suvida_id as (
	select 
		siw.suvida_id, 
		count(distinct siw_o.suvida_id) as current_run_cluster_count
	from dw_dev.dev_jkizer.suvida_id_walk siw 
	inner join source_prod.suvida_eid.src_suvida_identifier_output siw_o
		on siw.member_id = siw_o.member_id
	group by 1
)
select 
	mc.suvida_id,
	mc.current_run_cluster_count,
	siw.member_id,
	siw.source,
	siw.run_datetime,
	ipi.* exclude (source, member_id),
from multiple_clusters_one_suvida_id mc
inner join dw_dev.dev_jkizer.suvida_id_walk siw 
	on mc.suvida_id = siw.suvida_id
inner join dw_dev.dev_jkizer.int_suvida_id_input ipi 
	on siw.member_id = ipi.member_id
where mc.current_run_cluster_count > 1
    )
;


  