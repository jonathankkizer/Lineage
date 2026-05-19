
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_program_process_overview
    copy grants
    
    
    as (select
	clinical_program_eligibility_skey ||'_eligible' as clinical_program_step_skey,
	date_month_start,
	date_month_end,
	suvida_id,
	team,
	program,
	'eligible' as clinical_program_step,
	1 as clinical_program_step_order,
	is_newly_eligible as is_new_to_step,
	true as clinical_program_step_status
from dw_dev.dev_jkizer.clinical_program_eligibility

union all

select 
	clinical_program_enrollment_skey || '_tag' as clinical_program_step_skey,
	date_month_start,
	date_month_end,
	suvida_id,
	enrollment_team as team,
	enrollment_program as program,
	'tag_enrollment' as clinical_program_step,
	4 as clinical_program_step_order,
	is_newly_enrolled as is_new_to_step,
	true as clinical_program_step_status
from dw_dev.dev_jkizer.clinical_program_enrollment
where enrollment_type = 'tag'

union all

select 
	clinical_program_enrollment_skey || '_visit' as clinical_program_step_skey,
	date_month_start,
	date_month_end,
	suvida_id,
	enrollment_team as team,
	enrollment_program as program,
	'visit_enrollment' as clinical_program_step,
	3 as clinical_program_step_order,
	is_newly_enrolled as is_new_to_step,
	true as clinical_program_step_status
from dw_dev.dev_jkizer.clinical_program_enrollment
where enrollment_type = 'visit'

union all

select
	clinical_program_referral_skey || '_referral' as clinical_program_step_skey,
	date_month_start,
	date_month_end,
	suvida_id,
	referral_team as team,
	referral_program as program,
	'referral' as clinical_program_step,
	2 as clinical_program_step_order,
	is_newly_referred as is_new_to_step,
	true as clinical_program_step_status
from dw_dev.dev_jkizer.clinical_program_referral
    )
;


  