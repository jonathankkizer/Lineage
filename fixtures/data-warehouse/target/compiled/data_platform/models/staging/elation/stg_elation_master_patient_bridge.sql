select
	to_varchar(mp.id) as master_elation_id,
	to_varchar(p.id) as elation_id,
	'Elation' as source,
	iff(p.DELETION_TIME is null, false, true) as is_patient_deleted,
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.master_patient mp
inner join elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient p
	on mp.id = p.master_id