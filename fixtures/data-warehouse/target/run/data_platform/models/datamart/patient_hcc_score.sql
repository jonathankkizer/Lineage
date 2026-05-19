
  
    

create or replace transient table dw_dev.dev_jkizer.patient_hcc_score
    copy grants
    
    
    as (select 
	hcc_period_patient_skey,
	suvida_id,
	period_type,
	period_start_date,
	period_end_date,
	period_month,
	monthname(period_month) as period_month_name,
	run_datetime,
	is_max_monthly_period,
	/* V24 EMR */
	v24_e_risk_score,
	v24_e_risk_score_adj,
	/* V24 EMR Claims */
	v24_ec_risk_score,
	v24_ec_risk_score_adj,
	/* V24 EMR Claims Retro */
	v24_ecr_risk_score,
	v24_ecr_risk_score_adj,
	/* V28 EMR */
	v28_e_risk_score,
	v28_e_risk_score_adj,
	/* V28 EMR Claims */
	v28_ec_risk_score,
	v28_ec_risk_score_adj,
	/* V28 EMR Claims Retro */
	v28_ecr_risk_score,
	v28_ecr_risk_score_adj,
	/* EMR Blended */
	blended_e_risk_score_adj,
	blended_e_risk_score,
	/* EMR Claims Blended */
	blended_ec_risk_score_adj,
	blended_ec_risk_score,
	/* EMR Claims Retro Blended */
	blended_ecr_risk_score_adj,
	blended_ecr_risk_score,
from dw_dev.dev_jkizer.fct_hcc_score hcc
where year(period_month) in (year(current_date), year(current_date) - 1)
    )
;


  