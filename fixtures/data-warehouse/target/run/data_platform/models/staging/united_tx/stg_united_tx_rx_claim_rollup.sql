
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_tx_rx_claim_rollup
  
  copy grants
  
  
  as (
    with part_b_pharm as (
	select
		case
			when len(member_alt_id) = 11 then right(replace(member_alt_id, '-1', ''), 7)::varchar || '01'
			else member_alt_id::varchar
		end as member_id,
		fillymd,
		amtpaid,
		src_file_name,
		audnbr,
	from airbyte_source_prod.united_tx.claims_rx
	where partbord = 'B'
), combined_data as (
	select
		member_id,
		'professional' as claim_type, -- Part B pharmacy claims
		to_date(fillymd, 'DDMonYYYY') as claim_start_date,
		amtpaid as paid_amount,
		audnbr,
		src_file_name,
		date(
			concat(
				regexp_substr(src_file_name, '\\d{4}'),
				regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)', 1, 1, 'i'),
				'01'
			),
			'YYYYMonDD'
		) as report_date
	from part_b_pharm
)
select
	*,
	dense_rank() over (partition by audnbr order by report_date desc) as claims_report_rank,
from combined_data
  );

