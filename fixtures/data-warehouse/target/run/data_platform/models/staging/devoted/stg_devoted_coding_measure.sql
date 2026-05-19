
  create or replace   view dw_dev.dev_jkizer_staging.stg_devoted_coding_measure
  
  copy grants
  
  
  as (
    select
	data:PatientID::varchar as member_id,
	year(date(data:ReportDate)) as measure_year,
	data:HccCode::varchar as measure_type,
	data:HccDescription::varchar as measure_type_description,
	replace(data:ModelVersion::varchar, 'V', '')::varchar as hcc_version,
	nullif(to_varchar(coalesce(data:DiagnosisCode, data:PriorYearDiagnosisCode)), '') as measure_dx_code,
	data:HccStatus::varchar as measure_status,
	data:IsPriorYearHcc::varchar as measure_detail,
	date(data:ReportDate) as report_date,
	'Devoted' as measure_source,
	split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
    data as data_variant,
from airbyte_source_prod.devoted.hcc_coding
  );

