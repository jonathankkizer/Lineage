select
       flr.suvida_id,
	   flr.collected_date as evidence_date,
		test_value as evidence_desc,
		year(flr.collected_date) as evidence_year,
        1 as suvida_numerator,
        1 as suvida_denominator,
        0 as pending_numerator,
        'Suvida - eGFR' as quality_measure ,
        object_construct(
            'evidence_date', flr.collected_date,
            'evidence_string', flr.test_value
        ) as evidence_array
 from dw_dev.dev_jkizer.fct_lab_result flr
 where flr.test_name in ('EGFR','eGFR non Afr Amer','eGFRcr CKD-EPI','eGFR')
 and flr.value_type = 'NM'
 group by all
 qualify row_number() over (partition by flr.suvida_id order by flr.collected_date desc) = 1