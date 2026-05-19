WITH cte_eligibile AS (
  SELECT 
    suvida_id,
    ICD_10_CODE,
    Diagnosis_date
  FROM dw_dev.dev_jkizer.fct_diagnosis
  WHERE (ICD_10_CODE LIKE '%I10%' 
     OR ICD_10_CODE LIKE '%E11%' 
     OR ICD_10_CODE LIKE '%E78%' 
     OR ICD_10_CODE LIKE '%E66%'
     OR ICD_10_CODE LIKE '%J44%' 
     OR ICD_10_CODE LIKE '%I25%' 
     OR ICD_10_CODE LIKE '%I48%' 
     OR ICD_10_CODE LIKE '%I73%' 
     OR ICD_10_CODE LIKE '%I70%' 
     OR ICD_10_CODE LIKE '%D50%')
    and source_type = 'emr'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY suvida_id ORDER BY Diagnosis_date DESC) = 1
),
cte_echo AS (
  select 
    suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		document_date as evidence_date,
		report_title as evidence_desc,
		year(document_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_elation_report
	where is_echo = 1 -- doctag logic to find echo reports
	qualify row_number() over (partition by suvida_id order by document_date desc) = 1

  union 

  SELECT 
    suvida_id,
    0 as suvida_numerator,
		1 as suvida_denominator,
		1 as pending_numerator,
    signed_date AS evidence_date,
    CONCAT(test_name, ' ; ', resolution_state, ' ; ', signed_date) AS evidence_desc,
    YEAR(signed_date) AS evidence_year
  FROM dw_dev.dev_jkizer.fct_misc_orders
  WHERE (LOWER(test_name) LIKE '%echocardiogram%' 
     OR LOWER(test_name) LIKE '%echocardiography%')
  and resolution_state = 'outstanding'
  qualify row_number() over (partition by suvida_id order by signed_date desc) = 1
)
SELECT 
  coalesce(ce.suvida_id, co.suvida_id) as suvida_id,
  co.evidence_date,
  co.evidence_year,
  co.evidence_desc,
  coalesce(co.suvida_numerator, 0) as suvida_numerator,
  coalesce(co. suvida_denominator, 1) as suvida_denominator,
  coalesce(co.pending_numerator, 0) as pending_numerator,
  'suvida-echo' AS quality_measure
FROM 
  cte_eligibile ce 
full JOIN ---if the patient doesn't have the diagnosis but has the test done need to pull the records
  cte_echo co 
  ON ce.suvida_id = co.suvida_id
QUALIFY ROW_NUMBER() OVER (PARTITION BY coalesce(ce.suvida_id, co.suvida_id) ORDER BY co.evidence_date DESC) = 1