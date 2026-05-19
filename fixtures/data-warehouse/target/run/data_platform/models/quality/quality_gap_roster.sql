
  create or replace   view dw_dev.dev_jkizer_quality.quality_gap_roster
  
    
    
(
  
    "ELATION_ID" COMMENT $$The patient's Elation ID$$, 
  
    "MEASURE_COMPLIANCE" COMMENT $$Measure compliance according to the payer$$, 
  
    "ELATION_COMPLIANCE" COMMENT $$Measure compliance according to Elation$$, 
  
    "REPORT_DATE" COMMENT $$The date the measure was reported on$$, 
  
    "REFRESH_DATE" COMMENT $$The last refresh of the data$$, 
  
    "DEFINITION_ID" COMMENT $$The Quality Care Gap Elation definition ID$$, 
  
    "CAREGAP_ID" COMMENT $$The Elation Care Gap ID$$, 
  
    "PRACTICE_ID" COMMENT $$The Elation practice ID$$, 
  
    "CREATED_DATE" COMMENT $$The date the Care Gap was created$$, 
  
    "STATUS" COMMENT $$The status of the Care Gap$$, 
  
    "CLOSED_DATE" COMMENT $$The date the Care Gap was closed$$, 
  
    "CLOSED_BY" COMMENT $$The user that closed the Care Gap$$, 
  
    "VARIANT_ID" COMMENT $$The Care Gap variant (version) ID$$
  
)

  copy grants
  
  
  as (
    

with cte_quality_gaps as (
     select -- synthetic AWV gap for entire population; use if no more recent AWV gap is available for the measure year
       suvida_id,
       'Annual Wellness Visit' as quality_measure,
       date_from_parts(year(current_date()), '01', '01') as measure_year,
       0 as measure_numerator,
       0 as suvida_numerator,
       'SVH_Suspect' as measure_source,
       creation_date as report_date,
       sysdate() as data_warehouse_refresh,
    from dw_dev.dev_jkizer.patient_summary ps
    
    union all
    
    select -- synthetic CBP gap for entire population; use if no more recent AWV gap is available for the measure year
         suvida_id,
         'Controlling Blood Pressure' as quality_measure,
         date_from_parts(year(current_date()), '01', '01') as measure_year,
         0 as measure_numerator,
         0 as suvida_numerator,
         'SVH_Suspect' as measure_source,
         creation_date as report_date,
         sysdate() as data_warehouse_refresh,
     from dw_dev.dev_jkizer.patient_summary ps
     
     union all
     
     select -- gaps from payer files, most recent for each patient for current measure year
        suvida_id,
        quality_measure,
        measure_year,
        measure_numerator,
        suvida_numerator,
        measure_source,
        report_date,
        sysdate() as data_warehouse_refresh,
     from dw_dev.dev_jkizer.patient_quality_measure
     where patient_measure_report_rank = 1
     and year(measure_year) = year(current_date())
), ranked_gaps as (
   select *
   from cte_quality_gaps
   qualify row_number() over (partition by suvida_id, quality_measure order by report_date desc) = 1
), existing_gaps as (
    select
        caregap_id,
        definition_id,
        patient_id,
        practice_id,
        created_date,
        closed_date,
        status,
        closed_by,
        as_integer(to_variant(details)) as variant_id
    from dw_dev.dev_jkizer_staging.stg_elation_health_care_gap gaps
    left join dw_dev.dev_jkizer_staging.stg_elation_health_care_gap_definition gdefs
        on trim(lower(gaps.definition_id)) = trim(lower(gdefs.id))
    where
        gdefs.class = 'Quality' and
        gaps.deleted_date is null
), max_variant_ids as (
    select
        patient_id,
        definition_id,
        max(coalesce(variant_id, 1)) as max_variant_id
    from existing_gaps
    group by
        patient_id,
        definition_id
), latest_existing_gaps as (
    select 
      existing_gaps.*
    from existing_gaps
    inner join max_variant_ids
        on existing_gaps.patient_id = max_variant_ids.patient_id and
        existing_gaps.definition_id = max_variant_ids.definition_id and
        existing_gaps.variant_id = max_variant_ids.max_variant_id
)
select
    ps.elation_id,
    as_integer(to_variant(qgaps.measure_numerator)) as measure_compliance,
    as_integer(to_variant(qgaps.suvida_numerator)) as elation_compliance,
    report_date,
    data_warehouse_refresh as refresh_date,
    defs.id as definition_id,
    exgaps.caregap_id,
    exgaps.practice_id,
    exgaps.created_date,
    exgaps.status,
    exgaps.closed_date,
    exgaps.closed_by,
    exgaps.variant_id
from dw_dev.dev_jkizer_staging.stg_sharepoint_svh_quality_gap_mappings qgmap
inner join ranked_gaps qgaps
    on qgmap.suvida_measure_name = qgaps.quality_measure
inner join dw_dev.dev_jkizer.patient_summary ps 
   on qgaps.suvida_id = ps.suvida_id
inner join dw_dev.dev_jkizer_staging.stg_elation_health_care_gap_definition defs
    on qgmap.elation_measure_name = defs.name
left join latest_existing_gaps exgaps
    on ps.elation_id = exgaps.patient_id and
    defs.id = exgaps.definition_id
where
    qgmap.is_enabled = TRUE and
    year(defs.start_date) = year(getdate()) and
    defs.class = 'Quality' and
    ps.is_active_patient = 1
  );

