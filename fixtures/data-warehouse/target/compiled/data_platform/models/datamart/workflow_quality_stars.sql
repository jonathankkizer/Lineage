select
    fqm.suvida_id,
    fqm.quality_measure,
    fqm.measure_source,
    fqm.measure_year,
    fqm.quality_measure_skey,
    fra.workflow_status_detail,
    r.workflow_status,
    fra.workflow_note,
    fra.workflow_attachment,
    fra.check_again_date,
    fra.last_modified_by_name,
    fra.last_modified_by_email,
    fra.last_modified_datetime,
    fra.is_automated_activity,
    fra.workflow_status_index,
    fra.osteo_fracture_date,
    fra.airtable_id,
    fqm.measure_numerator,
    coalesce(fra.is_qualifying_review, false) as is_qualifying_review,
from dw_dev.dev_jkizer.fct_quality_measure fqm
left join dw_dev.dev_jkizer.fct_quality_review_activity fra
    on fqm.quality_measure_skey = fra.quality_measure_skey
left join dw_dev.dev_jkizer_source.map_quality_workflow_rollup r
    on fra.workflow_status_detail = r.workflow_status_detail
where fqm.quality_measure_report_rank = 1