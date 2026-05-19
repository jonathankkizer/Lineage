with med_adh_skeys as (
	select
		iff(split_mad_by_drug = true and quality_measure = 'Med Adherence - Diabetes' and measure_year = '2026-01-01',
			md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ima.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_detail as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(drug_name_category as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)),
			md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ima.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_detail as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
		) as med_adherence_measure_report_skey,
		/*
		United gives us all diabetes drugs for Diabetes Med Adherence; other payers only give one. This code changes how we determine uniqueness to preserve information related to different drugs
		*/
		iff(split_mad_by_drug = true and quality_measure = 'Med Adherence - Diabetes' and measure_year = '2026-01-01',
			md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ima.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(drug_name_category as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)),
			md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ima.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)))
			as med_adherence_measure_skey,
		siw.suvida_id,
		ima.member_id,
		quality_measure,
		quality_measure_type,
		measure_weight,
		lis_level,
		is_single_fill,
		measure_year,
		measure_status,
		measure_status_v2,
		measure_numerator,
		measure_numerator_v2,
		measure_denominator,
		perc_days_covered,
		ninety_day_opportunity,
		gap_days_remaining,
		rx_name,
		rx_number,
		member_status,
		prescriber_name,
		prescriber_phone,
		last_fill_day_supply,
		last_fill_date,
		next_refill_due,
		refills_remaining,
		rx_tier,
		first_fill_date,
		number_of_fills,
		pharmacy_name,
		pharmacy_phone,
		pharmacy_address,
		measure_program,
		payer_group,
		report_date,
		date_trunc(month, report_date) as report_month,
		measure_source,
		src_file_name,
		report_type,
		split_mad_by_drug,
		drug_name_category,
		claim_reversal,
		absolute_fail_date,
		case
    		when next_refill_due < current_date()
     		and gap_days_remaining - datediff(day, report_date, current_date()) >= 0
    		then gap_days_remaining - datediff(day, report_date, current_date())
    		else gap_days_remaining
		end as real_time_gdr
	from dw_dev.dev_jkizer.intmdt_med_adherence ima
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on ima.member_id = siw.member_id
		-- CODE SMELL: fix ASAP once source names are standardized upstream.
		-- quality/med adherence data labels all Wellcare members (TX and AZ) as 'Wellcare/Centene',
		-- but suvida_id_walk preserves 'Wellcare AZ' for AZ members. Normalize on the walk side so
		-- AZ patients flow through while keeping this as a hash-joinable equijoin.
		and ima.measure_source = case when siw.source = 'Wellcare AZ' then 'Wellcare/Centene' else siw.source end
	where ima.payer_suvida_measure_match = true -- remove any non-matching quality measures
)
select
	*,
	-- latest report for each unique patient-measure-year combo (med_adherence_measure_skey)
	dense_rank() over (partition by suvida_id, member_id, measure_year, quality_measure, iff(split_mad_by_drug = true and quality_measure = 'Med Adherence - Diabetes' and measure_year = '2026-01-01', drug_name_category, null) order by report_date desc) as med_adherence_report_rank,
	-- latest report file across all patients/measures for this payer; used for is_current_report flag
	-- dense_rank() over (partition by measure_source order by report_date desc) as report_rank,
	-- latest report for each payer within each measurement year and report_type
	dense_rank() over (partition by measure_source, measure_year, report_type order by report_date desc) as measure_year_report_rank,
	-- latest report for this patient across all measures
	dense_rank() over (partition by suvida_id order by report_date desc) as patient_report_rank,
	-- latest report for this patient for this specific measure type
	dense_rank() over (partition by suvida_id, quality_measure order by report_date desc) as patient_measure_report_rank,
	-- latest report within each calendar month per payer/measure_year/report_type; primary filter for monthly tracking
	dense_rank() over (partition by measure_source, measure_year, report_type, report_month order by report_date desc) as med_adherence_report_in_month_rank,
	-- chronological order (1 = earliest); used for is_first_measure_appearance flag
	row_number() over (partition by suvida_id, member_id, measure_year, quality_measure, iff(split_mad_by_drug = true and quality_measure = 'Med Adherence - Diabetes' and measure_year = '2026-01-01', drug_name_category, null) order by report_date asc) as med_adherence_measure_rn,
	iff(
		lead(last_fill_date) over (
			partition by suvida_id, quality_measure, measure_year
			order by report_date
		) < last_fill_date
		or claim_reversal = '1',
		true,
		false
	) as is_suspected_claim_reversal,
	case
		/* Currently Non-Adherent */
		when measure_source = 'Devoted' and perc_days_covered < 80 and lower(member_status) != 'na - failed measure and guaranteed non-adherent' then 'Currently Non-Adherent'
		when measure_source = 'UHG/Wellmed' and perc_days_covered < 80 and lower(member_status) != 'failed-no remaining gap days' then 'Currently Non-Adherent'
		when measure_source = 'Wellcare/Centene' and perc_days_covered < 80 and lower(member_status) = 'in-play' then 'Currently Non-Adherent'
		/* Currently Adherent */
		when measure_source = 'Devoted' and perc_days_covered >= 80 and lower(member_status) != 'na - guaranteed adherent' then 'Currently Adherent'
		when measure_source = 'UHG/Wellmed' and perc_days_covered >= 80 and lower(member_status) != 'pass' then 'Currently Adherent'
		when measure_source = 'Wellcare/Centene' and perc_days_covered >= 80 and lower(member_status) = 'in-play' then 'Currently Adherent'
		/* Permanently Adherent */
		when measure_source = 'Devoted' and perc_days_covered < 80 and lower(member_status) = 'na - guaranteed adherent' then 'Permanently Adherent'
		when measure_source = 'UHG/Wellmed' and perc_days_covered < 80 and lower(member_status) = 'pass' then 'Permanently Adherent'
		when measure_source = 'Wellcare/Centene' and perc_days_covered < 80 and lower(member_status) = ' ' then 'Permanently Adherent'
		/* Permanently Non-Adherent */
		when measure_source = 'Devoted' and perc_days_covered >= 80 and lower(member_status) = 'na - failed measure and guaranteed non-adherent' then 'Permanently Non-Adherent'
		when measure_source = 'UHG/Wellmed' and perc_days_covered >= 80 and lower(member_status) = 'failed-no remaining gap days' then 'Permanently Non-Adherent'
		when measure_source = 'Wellcare/Centene' and perc_days_covered >= 80 and lower(member_status) = 'unattainable' then 'Permanently Non-Adherent'
		else 'Currently Not Eligible'
	end as measure_compliance_desc,
from med_adh_skeys