select
	UQ_DOCUMENT_TAG as uq_document_tag_id,
	ID as document_tag_id,
	PRACTICE_ID as practice_id,
	VALUE as document_tag_value,
	DESCRIPTION as document_tag_description,
	CODE_TYPE as code_type,
	CODE as code_value,
	CONCEPT_NAME as concept_name,
	CREATION_TIME as creation_datetime,
	CREATED_BY_USER_ID as created_by_user_id,
	'Elation' as source,
	row_number() over (partition by UQ_DOCUMENT_TAG order by HDB_LAST_SYNC desc) as _rn -- 1 is most recent record
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.document_tag
where DELETION_TIME is null