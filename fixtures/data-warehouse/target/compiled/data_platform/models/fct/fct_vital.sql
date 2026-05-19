with cte_bp_vitals as (
	select 
    	vital_id, 
    	count(*) as number_of_bp_readings, 
    	sum(iff(is_controlled_blood_pressure = true, 1, 0)) as number_compliant_bp_readings, 
    	sum(iff(is_controlled_blood_pressure = false, 1, 0)) as number_noncompliant_bp_readings,
		min(blood_pressure_systolic) as min_blood_pressure_systolic,
		min(blood_pressure_diastolic) as min_blood_pressure_diastolic,
	from dw_dev.dev_jkizer_staging.stg_elation_vitals_bp
	where blood_pressure_systolic is not null
      and blood_pressure_diastolic is not null
	group by all
)

select
	siw.suvida_id,
	v.vital_id,
	v.practice_id,
	v.visit_note_id,
	-- TO DO: add either key to join to appointment/encounter info or add here
	bp.min_blood_pressure_systolic,
	bp.min_blood_pressure_diastolic,
	case 
        when min_blood_pressure_systolic is null
            or min_blood_pressure_diastolic is null
        then null
		when min_blood_pressure_systolic < 140 
			and min_blood_pressure_diastolic < 90 
		then true 
		else false
		end 
	as is_lowest_value_controlled_blood_pressure,
	case 
		when 
			bp.min_blood_pressure_systolic is null then null 
		else 
			concat(to_varchar(bp.min_blood_pressure_systolic), '/', to_varchar(bp.min_blood_pressure_diastolic))
		end 
	as lowest_blood_pressure_text,
	v.blood_pressure_systolic,
	v.blood_pressure_diastolic,
	case 
		when 
			v.blood_pressure_systolic is null then null 
		else 
			concat(to_varchar(v.blood_pressure_systolic), '/', to_varchar(v.blood_pressure_diastolic))
	end as blood_pressure_text,
	v.bp_note,
	v.is_controlled_blood_pressure,
	bp.number_of_bp_readings,
	bp.number_compliant_bp_readings,
	bp.number_noncompliant_bp_readings,
	v.height,
	v.height_units,
	v.height_note,
	v.weight,
	v.weight_units,
	v.weight_note,
	v.bmi,
	v.heart_rate,
	v.heart_rate_note,
	v.oxygen_percent,
	v.oxygen_note,
	v.pain,
	v.pain_note,
	v.respiratory_rate,
	v.respiratory_rate_note,
	v.temperature,
	v.temperature_units,
	v.document_datetime, 
	v.chart_feed_datetime,
	v.last_modified_datetime,
	v.creation_datetime,
	v.created_by_user_id,
	seu.user_name as created_by_user_name
from dw_dev.dev_jkizer_staging.stg_elation_vital v
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on v.patient_id = siw.member_id
	and v._source = siw.source
left join cte_bp_vitals bp 
	on v.vital_id = bp.vital_id
left join dw_dev.dev_jkizer_staging.stg_elation_user seu  
	on v.created_by_user_id = seu.user_id