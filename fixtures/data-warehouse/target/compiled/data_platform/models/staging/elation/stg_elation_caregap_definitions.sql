select
    DEFINITION_ID as definition_id,
    QUALITY_PROGRAM as quality_program,
    DESCRIPTION as description,
    NAME as name,
    LINKS as links,
    OVERRIDE_REASONS as override_reasons,
    CLOSING_CODES as closing_codes,
    SUGGESTIONS as suggestions,
    INDICATOR as indicator,
    IS_DELETED as is_deleted,
    START_DATE as start_date,
    END_DATE as end_date
    --WAREHOUSE_ID
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.caregap_definitions