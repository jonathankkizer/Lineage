
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_az_rx_claim_rollup
  
  copy grants
  
  
  as (
    with part_b_pharm as (
	select case
			when len(member_alt_id) = 11 then right(replace(member_alt_id, '-1', ''), 7)::varchar || '01'
			else member_alt_id::varchar
		end as member_id, fillymd, amtpaid, src_file_name, audnbr,
	from SOURCE_PROD.united.src_united_csp_rx_claim_2025_1
	where partbord = 'B'
	
	union all
	
	select case
			when len(member_alt_id) = 11 then right(replace(member_alt_id, '-1', ''), 7)::varchar || '01'
			else member_alt_id::varchar
		end as member_id, fillymd, amtpaid, src_file_name, audnbr,
	from SOURCE_PROD.united.src_united_rx_claim_hmo_phoenix_2025_1
	where partbord = 'B'
	
	union all
	
	select case
			when len(member_alt_id) = 11 then right(replace(member_alt_id, '-1', ''), 7)::varchar || '01'
			else member_alt_id::varchar
		end as member_id, fillymd, amtpaid, src_file_name, audnbr,
	from SOURCE_PROD.united.src_united_rx_claim_ppo_phoenix_2025_1
	where partbord = 'B'
	
	union all
	
	select case
			when len(member_alt_id) = 11 then right(replace(member_alt_id, '-1', ''), 7)::varchar || '01'
			else member_alt_id::varchar
		end as member_id, fillymd, amtpaid, src_file_name, audnbr,
	from SOURCE_PROD.united.src_united_rx_claim_ppo_tucson_2025_1
	where partbord = 'B'
	
	union all
	
	select case
			when len(member_alt_id) = 11 then right(replace(member_alt_id, '-1', ''), 7)::varchar || '01'
			else member_alt_id
		end as member_id, fillymd, amtpaid, src_file_name, audnbr,
	from SOURCE_PROD.united.src_united_rx_claim_hmo_tucson_2025_1
	where partbord = 'B'
), combined_data as (
	select
		member_id,
		'professional' as claim_type, -- these are Part B Pharmacy claims
		to_date(fillymd, 'DDMonYYYY') as claim_start_date,
		amtpaid as paid_amount,
		audnbr,
		src_file_name,
		date_from_parts(
					-- year (+1 if _RUNOUT)
					TO_NUMBER(REGEXP_SUBSTR(src_file_name, '\\d{4}'))
					+ IFF(src_file_name ilike '%_runout%', 1, 0),
					-- month number (case-insensitive match via 'i' flag)
					MONTH(
						TO_DATE(
							'01-' || REGEXP_SUBSTR(src_file_name,
												   '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
												   1, 1, 'i')            -- ← flag here
							|| '-2000',
							'DD-MON-YYYY'
						)
					),
					1   -- always day 1
				) as report_date
	from part_b_pharm
)
select
	*,
	dense_rank() over (partition by audnbr order by report_date desc) as claims_report_rank,
from combined_data
  );

