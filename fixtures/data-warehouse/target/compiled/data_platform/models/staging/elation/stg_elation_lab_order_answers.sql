select 
    UQ_LAB_ORDER_ANSWERS as uq_lab_order_answers_code,
    ID as lab_order_answers_id,
    SEQUENCE as lab_order_answers_sequence,
    QUESTION as question,
    QUESTION_CODE as question_code,
    ANSWER as answer,
    LAB_ORDER_ID as lab_order_id,
    QUESTION_ID as question_id,
    LAB_ORDER_TESTS_ID as lab_order_tests_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.lab_order_answers