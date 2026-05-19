select
  UQ_LAB_ORDER_TESTS as uq_lab_order_tests,
  ID as lab_order_tests_id,
  TEST_ID as test_id,
  LAB_ORDER_ID as lab_order_id,
  NAME as order_test_name,
  CODE as test_code,
  WAREHOUSE_ID as warehouse_id,
  HDB_LAST_SYNC as hdb_last_sync,
  row_number() over (partition by LAB_ORDER_ID, CODE order by HDB_LAST_SYNC desc) as lab_order_tests_index,
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.lab_order_tests