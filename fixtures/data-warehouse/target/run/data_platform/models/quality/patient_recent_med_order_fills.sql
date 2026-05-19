
  
    

create or replace transient table dw_dev.dev_jkizer_quality.patient_recent_med_order_fills
    copy grants
    
    
    as (select
    suvida_id
    ,med_order_id
    ,med_start_date
    ,expected_reorder_date
    ,displayed_medication_name
    ,med_type
    ,med_route
    ,strength
    ,form
    ,auth_refills
    ,origin
    ,last_fill_date
    ,days_supply 
    ,pharmacy_name
    ,pharmacy_address_line1
    ,pharmacy_address_line2
    ,pharmacy_city
    ,pharmacy_state
    ,pharmacy_zip
    ,pharmacy_phone_primary
    ,pharmacy_npi
    ,case when lower(displayed_medication_name) LIKE '%metformin%' 
        OR lower(displayed_medication_name) LIKE '%glyburide%' 
        OR lower(displayed_medication_name) LIKE '%glipizide%' 
        OR lower(displayed_medication_name) LIKE '%glimepiride%' 
        OR lower(displayed_medication_name) LIKE '%sitagliptin%' 
        OR lower(displayed_medication_name) LIKE '%saxagliptin%' 
        OR lower(displayed_medication_name) LIKE '%linagliptin%' 
        OR lower(displayed_medication_name) LIKE '%liraglutide%' 
        OR lower(displayed_medication_name) LIKE '%exenatide%' 
        OR lower(displayed_medication_name) LIKE '%dulaglutide%' 
        OR lower(displayed_medication_name) LIKE '%canagliflozin%' 
        OR lower(displayed_medication_name) LIKE '%dapagliflozin%' 
        OR lower(displayed_medication_name) LIKE '%empagliflozin%' 
        OR lower(displayed_medication_name) LIKE '%Atorvastatin%'
        OR lower(displayed_medication_name) LIKE '%Lipitor%' 
        OR lower(displayed_medication_name) LIKE '%rosuvastatin%' 
        OR lower(displayed_medication_name) LIKE '%crestor%'
        OR lower(displayed_medication_name) LIKE '%simvastatin%' 
        OR lower(displayed_medication_name) LIKE '%Zocor%' 
        OR lower(displayed_medication_name) LIKE '%pravastatin%'
        OR lower(displayed_medication_name) LIKE '%pravachol%' 
        OR lower(displayed_medication_name) LIKE '%lovastatin%'
        OR lower(displayed_medication_name) LIKE '%mevacor%' 
        OR lower(displayed_medication_name) LIKE '%lisinopril%' 
        OR lower(displayed_medication_name) LIKE '%enalapril%' 
        OR lower(displayed_medication_name) LIKE '%ramipril%' 
        OR lower(displayed_medication_name) LIKE '%benazepril%' 
        OR lower(displayed_medication_name) LIKE '%losartan%' 
        OR lower(displayed_medication_name) LIKE '%valsartan%' 
        OR lower(displayed_medication_name) LIKE '%candesartan%' 
        OR lower(displayed_medication_name) LIKE '%olmesartan%' 
    then 1 else 0 end as quality_related_med 
    FROM dw_dev.dev_jkizer.patient_med_order_fill
    WHERE med_order_fill_rank = 1
    )
;


  