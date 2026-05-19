select
    UQ_CLINICAL_FORM_COLLECTION as uq_clinical_form_collection,	
    ITEM_ID	as item_id,
    PATIENT_ID	as patient_id,
    FORM_NAME as form_name, 	
    FORM_CATEGORY as form_category,	
    ANSWER as answer,	
    CLINICAL_FORM_QUESTION as clinical_form_question,	
    SEQUENCE_NUMBER	as sequence_number,
    LOINC_ANSWER_CODE as loinc_answer_code,	
    SCORE as score,	
    ANSWER_TYPE as answer_type,
    LOINC_CODE as loinc_code,
    CREATION_TIME as creation_time,	
    CREATED_BY_USER_ID	as created_by_user_id,
    IS_DELETED as is_deleted,	
    --WAREHOUSE_ID	
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ITEM_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.clinical_form_collection