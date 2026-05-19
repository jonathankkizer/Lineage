with current_history as (
select
	suvida_id,
	max(iff(history_type = 'Mini-Cog' and patient_history_index = 1, history_value_numeric, null)) as mini_cog_value,
	max(iff(history_type = 'Mini-Cog' and patient_history_index = 1, creation_datetime, null)) as mini_cog_date,
	max(iff(history_type = 'GAD-7' and patient_history_index = 1, history_value_numeric, null)) as gad_7_value,
	max(iff(history_type = 'GAD-7' and patient_history_index = 1, creation_datetime, null)) as gad_7_date,
	max(iff(history_type = 'GAD-7' and year(creation_datetime) = 2024, history_value_numeric, null)) as max_gad_7_value_2024,
	max(iff(history_type = 'GAD-7' and year(creation_datetime) = 2025, history_value_numeric, null)) as max_gad_7_value_2025,
	max(iff(history_type = 'GAD-7' and year(creation_datetime) = 2026, history_value_numeric, null)) as max_gad_7_value_2026,
	max(iff(history_type = 'PHQ-9' and patient_history_index = 1, history_value_numeric, null)) as phq_9_value,
	max(iff(history_type = 'PHQ-9' and patient_history_index = 1, creation_datetime, null)) as phq_9_date,
	max(iff(history_type = 'PHQ-9' and year(creation_datetime) = 2024, history_value_numeric, null)) as max_phq_9_value_2024,
	max(iff(history_type = 'PHQ-9' and year(creation_datetime) = 2025, history_value_numeric, null)) as max_phq_9_value_2025,
	max(iff(history_type = 'PHQ-9' and year(creation_datetime) = 2026, history_value_numeric, null)) as max_phq_9_value_2026,
	max(iff(history_type = 'PHQ-2' and patient_history_index = 1, history_value_numeric, null)) as phq_2_value,
	max(iff(history_type = 'PHQ-2' and patient_history_index = 1, creation_datetime, null)) as phq_2_date,
	max(iff(history_type = 'PHQ-2' and year(creation_datetime) = 2024, history_value_numeric, null)) as max_phq_2_value_2024,
	max(iff(history_type = 'PHQ-2' and year(creation_datetime) = 2025, history_value_numeric, null)) as max_phq_2_value_2025,
	max(iff(history_type = 'PHQ-2' and year(creation_datetime) = 2026, history_value_numeric, null)) as max_phq_2_value_2026,
	max(iff(history_type = 'Alcohol use' and patient_history_index = 1, history_value_numeric, null)) as alcohol_use_audit_c_value,
	max(iff(history_type = 'SmokingStatus' and patient_history_index = 1, history_value, null)) as smoker_status_value,
	nullif(listagg(iff(history_type = 'Surgical', history_value, null)), '') as surgical_history_value,
	max(iff(history_type = 'TUG' and patient_history_index = 1, history_value, null)) as tug_score_value,
	max(iff(history_type = 'Pre-TUG' and patient_history_index = 1, history_value, null)) as pre_tug_value,
	max(iff(history_type = 'Pre-TUG' and patient_history_index = 1, creation_datetime, null)) as pre_tug_date,
	max(iff(history_type = 'Post-TUG' and patient_history_index = 1, history_value, null)) as post_tug_value,
	max(iff(history_type = 'Post-TUG' and patient_history_index = 1, creation_datetime, null)) as post_tug_date,
	max(iff(history_type = 'Pre-Chair-Stand' and patient_history_index = 1, history_value, null)) as pre_chair_stand_value,
	max(iff(history_type = 'Pre-Chair-Stand' and patient_history_index = 1, creation_datetime, null)) as pre_chair_stand_date,
	max(iff(history_type = 'Post-Chair-Stand' and patient_history_index = 1, history_value, null)) as post_chair_stand_value,
	max(iff(history_type = 'Post-Chair-Stand' and patient_history_index = 1, creation_datetime, null)) as post_chair_stand_date,
from dw_dev.dev_jkizer.fct_patient_history
where suvida_id is not null
group by all
)
select
	*
from current_history
where (mini_cog_value is not null
	or mini_cog_date is not null
	or gad_7_value is not null
	or gad_7_date is not null
	or max_gad_7_value_2024 is not null
	or max_gad_7_value_2025 is not null
	or max_gad_7_value_2026 is not null
	or phq_9_value is not null
	or phq_9_date is not null
	or max_phq_9_value_2024 is not null
	or max_phq_9_value_2025 is not null
	or max_phq_9_value_2026 is not null
	or phq_2_value is not null
	or phq_2_date is not null
	or max_phq_2_value_2024 is not null
	or max_phq_2_value_2025 is not null
	or max_phq_2_value_2026 is not null
	or alcohol_use_audit_c_value is not null
	or smoker_status_value is not null
	or surgical_history_value is not null
	or tug_score_value is not null
	or pre_tug_value is not null
	or pre_tug_date is not null
	or post_tug_value is not null
	or post_tug_date is not null
    or pre_chair_stand_value is not null
	or pre_chair_stand_date is not null
	or post_chair_stand_value is not null
	or post_chair_stand_date is not null)