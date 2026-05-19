
  
    

create or replace transient table dw_dev.dev_jkizer.stars_score
    copy grants
    
    
    as (with payer_compliance_rates as (
	select 
		'payer' as star_score_granularity,
		least_ignore_nulls(date_trunc(month, report_date), to_date(year(measure_year) || '-12-01')) as glidepath_month,
		measure_year,
		measure_source,
		quality_measure,
		round(div0null(sum(performance_numerator), sum(measure_denominator)), 2) as measure_compliance,
		round(div0null(sum(quality_engine_measure_numerator), sum(measure_denominator)), 2) as quality_engine_measure_compliance,
	from dw_dev.dev_jkizer.patient_quality_measure pqm
	where quality_measure not in ('Med Adherence - RAS', 'Med Adherence - Diabetes', 'Med Adherence - Statins')
	group by all
	
	union all
	
	select 
		'payer' as star_score_granularity,
		least_ignore_nulls(date_trunc(month, report_date), to_date(year(measure_year) || '-12-01')) as glidepath_month,
		measure_year,
		measure_source,
		quality_measure,
		round(div0null(sum(measure_numerator), sum(measure_denominator)), 2) as measure_compliance,
		round(div0null(sum(measure_numerator), sum(measure_denominator)), 2) as quality_engine_measure_compliance,
	from dw_dev.dev_jkizer.patient_med_adherence pqm
	where quality_measure in ('Med Adherence - RAS','Med Adherence - Diabetes','Med Adherence - Statins')
    and is_single_fill = 0
    and med_adherence_report_rank = 1
	group by all
), location_payer_compliance_rates as (
	select 
		'location_payer' as star_score_granularity,
		least_ignore_nulls(date_trunc(month, report_date), to_date(year(measure_year) || '-12-01')) as glidepath_month,
		measure_year,
		measure_source,
		location_name,
		quality_measure,
		round(div0null(sum(performance_numerator), sum(measure_denominator)), 2) as measure_compliance,
		round(div0null(sum(quality_engine_measure_numerator), sum(measure_denominator)), 2) as quality_engine_measure_compliance,
	from dw_dev.dev_jkizer.patient_quality_measure pqm
	left join dw_dev.dev_jkizer.patient_summary ps
		using(suvida_id)
	where quality_measure not in ('Med Adherence - RAS', 'Med Adherence - Diabetes', 'Med Adherence - Statins')
	group by all
	
	union all
	
	select 
		'location_payer' as star_score_granularity,
		least_ignore_nulls(date_trunc(month, report_date), to_date(year(measure_year) || '-12-01')) as glidepath_month,
		measure_year,
		measure_source,
		location_name,
		quality_measure,
		round(div0null(sum(measure_numerator), sum(measure_denominator)), 2) as measure_compliance,
		round(div0null(sum(measure_numerator), sum(measure_denominator)), 2) as quality_engine_measure_compliance,
	from dw_dev.dev_jkizer.patient_med_adherence pqm
	left join dw_dev.dev_jkizer.patient_summary ps
		using(suvida_id)
	where quality_measure in ('Med Adherence - RAS','Med Adherence - Diabetes','Med Adherence - Statins')
	and is_single_fill = 0
	and med_adherence_report_rank = 1
	group by all
), compliance_rate as (
	select
		star_score_granularity,
		glidepath_month,
		measure_year,
		measure_source,
		null as location_name,
		quality_measure,
		measure_compliance,
		quality_engine_measure_compliance,
	from payer_compliance_rates
	
	union all
	
	select
		star_score_granularity,
		glidepath_month,
		measure_year,
		measure_source,
		location_name,
		quality_measure,
		measure_compliance,
		quality_engine_measure_compliance,
	from location_payer_compliance_rates
), star_scores as (
	select
		cr.*,
		sm.is_inverted,
		case when sm.is_inverted then
				case
					when measure_compliance <= coalesce(sct.star_6, -999) then 6
					when measure_compliance <= sct.star_5 then 5
					when measure_compliance <= sct.star_4_5 then 4.5
					when measure_compliance <= sct.star_4 then 4
					when measure_compliance <= sct.star_3 then 3
					when measure_compliance <= sct.star_2 then 2
					when measure_compliance > sct.star_2 then 1
					end
				else
				case
					when measure_compliance < sct.star_2 then 1
					when measure_compliance >= sct.star_2 and measure_compliance < sct.star_3 then 2
					when measure_compliance >= sct.star_3 and measure_compliance < sct.star_4 then 3
					when measure_compliance >= sct.star_4 and measure_compliance < coalesce(sct.star_4_5, sct.star_5) then 4
					when measure_compliance >= sct.star_4_5 and measure_compliance < sct.star_5 then 4.5
					when measure_compliance >= sct.star_5 and measure_compliance < coalesce(sct.star_6, 999) then 5
					when measure_compliance >= sct.star_6 then 6
					end
			end
		as measure_star_score,
		case when sm.is_inverted then
				case
					when quality_engine_measure_compliance <= coalesce(sct.star_6, -999) then 6
					when quality_engine_measure_compliance <= sct.star_5 then 5
					when quality_engine_measure_compliance <= sct.star_4_5 then 4.5
					when quality_engine_measure_compliance <= sct.star_4 then 4
					when quality_engine_measure_compliance <= sct.star_3 then 3
					when quality_engine_measure_compliance <= sct.star_2 then 2
					when quality_engine_measure_compliance > sct.star_2 then 1
					end
				else
				case
					when quality_engine_measure_compliance < sct.star_2 then 1
					when quality_engine_measure_compliance >= sct.star_2 and quality_engine_measure_compliance < sct.star_3 then 2
					when quality_engine_measure_compliance >= sct.star_3 and quality_engine_measure_compliance < sct.star_4 then 3
					when quality_engine_measure_compliance >= sct.star_4 and quality_engine_measure_compliance < coalesce(sct.star_4_5, sct.star_5) then 4
					when quality_engine_measure_compliance >= sct.star_4_5 and quality_engine_measure_compliance < sct.star_5 then 4.5
					when quality_engine_measure_compliance >= sct.star_5 and quality_engine_measure_compliance < coalesce(sct.star_6, 999) then 5
					when quality_engine_measure_compliance >= sct.star_6 then 6
					end
			end
		as quality_engine_measure_star_score,
		sct.star_2,
		sct.star_3,
		sct.star_4,
		sct.star_4_5,
		sct.star_5,
		sct.star_6,
		sct.star_weight,
	from compliance_rate cr
	left join dw_dev.dev_jkizer_staging.stg_star_measures sm
		on cr.quality_measure = sm.measure_name
	left join dw_dev.dev_jkizer.stars_cutpoint sct
		on cr.quality_measure = sct.quality_measure
		and year(cr.measure_year) = sct.measure_year
		and cr.measure_source = sct.measure_source
), star_scores_suvida as (
	select
		st.*,
		case when st.is_inverted then
				case
					when measure_compliance <= coalesce(sc.star_6, -999) then 6
					when measure_compliance <= sc.star_5 then 5
					when measure_compliance <= sc.star_4_5 then 4.5
					when measure_compliance <= sc.star_4 then 4
					when measure_compliance <= sc.star_3 then 3
					when measure_compliance <= sc.star_2 then 2
					when measure_compliance > sc.star_2 then 1
					end
				else
				case
					when measure_compliance < sc.star_2 then 1
					when measure_compliance >= sc.star_2 and measure_compliance < sc.star_3 then 2
					when measure_compliance >= sc.star_3 and measure_compliance < sc.star_4 then 3
					when measure_compliance >= sc.star_4 and measure_compliance < coalesce(sc.star_4_5, sc.star_5) then 4
					when measure_compliance >= sc.star_4_5 and measure_compliance < sc.star_5 then 4.5
					when measure_compliance >= sc.star_5 and measure_compliance < coalesce(sc.star_6, 999) then 5
					when measure_compliance >= sc.star_6 then 6
					end
			end
		as measure_star_score_suvida,
		case when st.is_inverted then
				case
					when quality_engine_measure_compliance <= coalesce(sc.star_6, -999) then 6
					when quality_engine_measure_compliance <= sc.star_5 then 5
					when quality_engine_measure_compliance <= sc.star_4_5 then 4.5
					when quality_engine_measure_compliance <= sc.star_4 then 4
					when quality_engine_measure_compliance <= sc.star_3 then 3
					when quality_engine_measure_compliance <= sc.star_2 then 2
					when quality_engine_measure_compliance > sc.star_2 then 1
					end
				else
				case
					when quality_engine_measure_compliance < sc.star_2 then 1
					when quality_engine_measure_compliance >= sc.star_2 and quality_engine_measure_compliance < sc.star_3 then 2
					when quality_engine_measure_compliance >= sc.star_3 and quality_engine_measure_compliance < sc.star_4 then 3
					when quality_engine_measure_compliance >= sc.star_4 and quality_engine_measure_compliance < coalesce(sc.star_4_5, sc.star_5) then 4
					when quality_engine_measure_compliance >= sc.star_4_5 and quality_engine_measure_compliance < sc.star_5 then 4.5
					when quality_engine_measure_compliance >= sc.star_5 and quality_engine_measure_compliance < coalesce(sc.star_6, 999) then 5
					when quality_engine_measure_compliance >= sc.star_6 then 6
					end
			end
		as quality_engine_measure_star_score_suvida,
		sc.star_2 as star_2_suvida,
		sc.star_3 as star_3_suvida,
		sc.star_4 as star_4_suvida,
		sc.star_4_5 as star_4_5_suvida,
		sc.star_5 as star_5_suvida,
		sc.star_6 as star_6_suvida,
		sc.star_weight as star_weight_suvida,
	from star_scores st
	left join dw_dev.dev_jkizer.stars_cutpoint_suvida sc
		on st.quality_measure = sc.quality_measure
		and year(st.measure_year) = sc.measure_year
), star_scores_glidepath as (
		select
		su.*,
		case when su.is_inverted then
				case
					when measure_compliance <= coalesce(sc.star_6, -999) then 6
					when measure_compliance <= sc.star_5 then 5
					when measure_compliance <= sc.star_4 then 4
					when measure_compliance <= sc.star_3 then 3
					when measure_compliance <= sc.star_2 then 2
					when measure_compliance > sc.star_2 then 1
					end
				else
				case
					when measure_compliance < sc.star_2 then 1
					when measure_compliance >= sc.star_2 and measure_compliance < sc.star_3 then 2
					when measure_compliance >= sc.star_3 and measure_compliance < sc.star_4 then 3
					when measure_compliance >= sc.star_4 and measure_compliance < sc.star_5 then 4
					when measure_compliance >= sc.star_5 and measure_compliance < coalesce(sc.star_6, 999) then 5
					when measure_compliance >= sc.star_6 then 6
					end
			end
		as measure_star_score_glidepath,
		case when su.is_inverted then
				case
					when quality_engine_measure_compliance <= coalesce(sc.star_6, -999) then 6
					when quality_engine_measure_compliance <= sc.star_5 then 5
					when quality_engine_measure_compliance <= sc.star_4 then 4
					when quality_engine_measure_compliance <= sc.star_3 then 3
					when quality_engine_measure_compliance <= sc.star_2 then 2
					when quality_engine_measure_compliance > sc.star_2 then 1
					end
				else
				case
					when quality_engine_measure_compliance < sc.star_2 then 1
					when quality_engine_measure_compliance >= sc.star_2 and quality_engine_measure_compliance < sc.star_3 then 2
					when quality_engine_measure_compliance >= sc.star_3 and quality_engine_measure_compliance < sc.star_4 then 3
					when quality_engine_measure_compliance >= sc.star_4 and quality_engine_measure_compliance < sc.star_5 then 4
					when quality_engine_measure_compliance >= sc.star_5 and quality_engine_measure_compliance < coalesce(sc.star_6, 999) then 5
					when quality_engine_measure_compliance >= sc.star_6 then 6
					end
			end
		as quality_engine_measure_star_score_glidepath,
		sc.star_2 as star_2_glidepath,
		sc.star_3 as star_3_glidepath,
		sc.star_4 as star_4_glidepath,
		sc.star_5 as star_5_glidepath,
		sc.star_6 as star_6_glidepath,
		sc.star_weight as star_weight_glidepath,
	from star_scores_suvida su
	left join dw_dev.dev_jkizer.stars_cutpoint_glidepath sc
		on su.quality_measure = sc.quality_measure
		and su.measure_year = date_trunc(year, sc.glidepath_month)
		and su.glidepath_month = sc.glidepath_month
)
select
	*,
	measure_star_score * star_weight as star_points,
	measure_star_score_suvida * star_weight_suvida as star_points_suvida,
	measure_star_score_glidepath * star_weight_glidepath as star_points_glidepath,
	quality_engine_measure_star_score * star_weight as quality_engine_star_points,
	quality_engine_measure_star_score_suvida * star_weight_suvida as quality_engine_star_points_suvida,
	quality_engine_measure_star_score_glidepath * star_weight_glidepath as quality_engine_star_points_glidepath,
from star_scores_glidepath
    )
;


  