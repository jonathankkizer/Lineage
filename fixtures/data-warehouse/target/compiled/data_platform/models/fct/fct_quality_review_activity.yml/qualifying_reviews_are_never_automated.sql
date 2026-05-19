



select
    1
from dw_dev.dev_jkizer.fct_quality_review_activity

where not(not (is_qualifying_review and is_automated_activity))

