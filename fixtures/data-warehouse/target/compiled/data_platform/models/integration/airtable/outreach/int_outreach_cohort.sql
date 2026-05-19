

select
    cohort_key,
    cohort_short_code,
    cohort_name,
    cohort_description,
    clinical_category,
    default_priority_tier::number as default_priority_tier,
    sla_days::number as sla_days,
    owning_team,
    active_flag::boolean as active_flag
from dw_dev.dev_jkizer_source.map_outreach_cohorts
where active_flag::boolean = true