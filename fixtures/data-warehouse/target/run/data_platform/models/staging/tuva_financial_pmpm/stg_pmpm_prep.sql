
  create or replace   view dw_dev.dev_jkizer_staging.stg_pmpm_prep
  
  copy grants
  
  
  as (
    select
	person_id as suvida_id,
	to_date(year_month, 'YYYYMM') as date_month,
	* exclude (person_id, year_month)
from suvida_tuva.financial_pmpm.pmpm_prep
where data_source in ('Devoted','Wellcare/Centene','UHG/Wellmed','United')
and to_date(year_month, 'YYYYMM') in ('2023-01-01','2023-02-01','2023-03-01','2023-04-01','2023-05-01','2023-06-01','2023-07-01','2023-08-01','2023-09-01','2023-10-01','2023-11-01','2023-12-01','2024-01-01','2024-02-01','2024-03-01','2024-04-01','2024-05-01','2024-06-01','2024-07-01','2024-08-01','2024-09-01','2024-10-01','2024-11-01','2024-12-01', '2025-01-01','2025-02-01','2025-03-01','2025-04-01','2025-05-01','2025-06-01','2025-07-01','2025-08-01','2025-09-01','2025-10-01','2025-11-01','2025-12-01','2026-01-01','2026-02-01')
and to_date(year_month, 'YYYYMM') <= dateadd(month, -3, current_date())
  );

