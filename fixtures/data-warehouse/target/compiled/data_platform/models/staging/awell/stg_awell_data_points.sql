select
    id as data_point_id,
    definition_id,
    release_id,
    care_flow_id,
    care_flow_definition_id,
    activity_id,
    value_raw,
    value_boolean,
    value_numeric,
    date(value_date) as value_date,
    label,
    value_type,
    date(date) as data_point_date,
    date(last_synced_at) as last_synced_at,
    status
 from source_prod.awell.data_points