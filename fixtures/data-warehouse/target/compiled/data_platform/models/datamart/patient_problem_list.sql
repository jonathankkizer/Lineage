select
	problem_list_skey,
	suvida_id,
	problem_id,
	problem_description,
	icd_10_code,
	icd_10_code_with_decimal,
	icd_10_code_description,
	start_date,
	last_modified_datetime,
	imo_code,
	problem_recency_rank,
	is_most_recent_problem
from dw_dev.dev_jkizer.fct_problem_list
where suvida_id is not null
and is_deleted = false