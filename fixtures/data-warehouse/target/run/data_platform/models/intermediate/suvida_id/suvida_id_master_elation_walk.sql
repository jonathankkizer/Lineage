
  
    

create or replace transient table dw_dev.dev_jkizer.suvida_id_master_elation_walk
    copy grants
    
    
    as (with master_patient_suvida_walk as ( -- pick up Elation Suvida IDs w/ master elation ID
	select distinct 
		mpb.master_elation_id, 
		siw.suvida_id,
		siw.member_id,
		siw.source,
		siw.run_datetime
	from dw_dev.dev_jkizer.suvida_id_walk siw
	inner join dw_dev.dev_jkizer_staging.stg_elation_master_patient_bridge mpb 
		on siw.member_id = mpb.elation_id
		and siw.source = mpb.source
) -- bump all patients w/ master patient ID against master_patient_suvida_walk to pick up suvida ID associated w/ master_elation_id
select 
	mpb.*,
	mpsw.suvida_id,
from dw_dev.dev_jkizer_staging.stg_elation_master_patient_bridge mpb
left join master_patient_suvida_walk mpsw
	on mpb.master_elation_id = mpsw.master_elation_id
    )
;


  