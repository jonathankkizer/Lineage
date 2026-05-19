
  create or replace   view dw_dev.dev_jkizer_staging.stg_svh_payor_quality_name
  
  copy grants
  
  
  as (
    with quality_measures as (
	select 
		abbreviations,
		replace(replace(trim(suvida_quality_measure),'—','-'), '–', '-') as quality_measure, -- standardized quality measure name
		weight as measure_weight,
		description,
		payer_name,
		payer_quality_name,
		quality_measure_type,
		row_number() over (partition by payer_name, payer_quality_name order by abbreviations desc) as _rn
	from dw_dev.dev_jkizer_source.map_payer_quality_names
	where quality_measure_type is not null)
select *
from quality_measures
where _rn = 1
  );

