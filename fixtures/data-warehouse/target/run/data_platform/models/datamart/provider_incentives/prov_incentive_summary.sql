
  
    

create or replace transient table dw_dev.dev_jkizer.prov_incentive_summary
    copy grants
    
    
    as (select 
	measure_year,
	provider_name,
	measure_group,
	measure_name,
	sum(measure_numerator) as passing_patients,
	sum(measure_denominator) as eligible_patients,
	sum(measure_numerator*1.0) / sum(measure_denominator*1.0) as perc_passing
from dw_dev.dev_jkizer.prov_incentive_combined
group by measure_year, provider_name, measure_group, measure_name
    )
;


  