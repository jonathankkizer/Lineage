
  
    

create or replace transient table dw_dev.dev_jkizer.suspect_morbid_obesity
    copy grants
    
    
    as (






with ob_comorbid as (
-- grab the latest diagnosis with additional info
    select
        suvida_id,
        diagnosis_date as latest_diagnosis_date,
        object_construct(
            'id', encounter_skey, 
            'icd_10_code', icd_10_code,
            'diagnosis_date', diagnosis_date, 
            'visit_note_id', visit_note_id
        ) as hcc_suspect_info_array
    from dw_dev.dev_jkizer.fct_diagnosis fd
    where replace(fd.icd_10_code, '.', '') in 
    ('I5010', 'I5011', 'I5012', 'I5013', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I5081', 'I5089', 'I509', 'I110', 'I130', 'I132', --Heart Failures
    
    'E100', 'E101', 'E102', 'E103', 'E104', 'E105', 'E106', 'E109', 'E110', 'E111', 'E112', 'E113', 'E114', 'E115', 'E116', 'E119', 'Z794', --Diabetes

    'I10', 'I110', 'I119', 'I120', 'I129', 'I130', 'I131', 'I132', 'I1310', 'I150', 'I151', 'I152', 'I158', 'I159', 'I160', 'I161', 'I169', --Hypertension

    'M150', 'M151', 'M152', 'M153', 'M154', 'M159', 'M160', 'M161', 'M1610', 'M162', 'M163', 'M164', 'M165', 'M166', 'M167', 'M169', 'M170', 'M171', 'M1710', 'M172', 'M173', 'M174', 'M175', 'M179', 'M180', 'M181', 'M182', 'M183', 'M184', 'M189', 'M190', 'M191', 'M192', 'M199', --Osteoarthritis

    'G4730', 'G4731', 'G4733', 'G4737', 'G4739', --Sleep Apnea

    'I700', 'I701', 'I70201', 'I70202', 'I70203', 'I70209', --Artherosclerosis 
 
    'E780', 'E781', 'E782', 'E783', 'E784', 'E786', 'E7870', 'E7871', 'E7879', 'E785') --Dyslipidemia 
    and source_type = 'emr'
    qualify row_number() over (partition by suvida_id order by diagnosis_date desc) = 1
), 

latest_bmi_values as (
-- grab the latest BMI values for patients
    select 
        suvida_id, 
        bmi,
        case when bmi >= 35 then 1 else 0 end as bmi_over_35_ind, 
        case when bmi >= 40 then 1 else 0 end as bmi_over_40_ind,
        object_construct(
            'vital_id', vital_id, 
            'bmi', bmi,
            'document_date', document_datetime
        ) as hcc_suspect_info_array
    from dw_dev.dev_jkizer.fct_vital ilv
    where suvida_id is not null
    qualify row_number() over (partition by suvida_id order by document_datetime desc) = 1
), 

patients_already_diagnosed_obesity as (
-- use to exclude patients in later CTEs, use HCC model V28 
-- Morbid Obesity --- HCC48
    select 
        hd.suvida_id
    from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd
	where hd.period_type = 'monthly' and hd.hcc_model = 28
	and hd.is_max_monthly_period = 1 and hd.hcc_code = '48'
    group by suvida_id
)

select 
    latest.suvida_id, 
    case 
        when bmi_over_35_ind = 1 and bmi_over_40_ind = 0 and ob_com.suvida_id is not null then 'E6601'
        when bmi_over_40_ind = 1 then 'E66813'
    end as suspect_icd_10_code, 
    bmi,
    array_construct(ob_com.hcc_suspect_info_array, latest.hcc_suspect_info_array) as hcc_suspect_info_array
from latest_bmi_values latest 
left join ob_comorbid ob_com 
    on ob_com.suvida_id = latest.suvida_id
left join patients_already_diagnosed_obesity pado 
    on pado.suvida_id = latest.suvida_id 
where pado.suvida_id is null and latest.bmi >= 35 and latest.bmi < 150
    )
;


  