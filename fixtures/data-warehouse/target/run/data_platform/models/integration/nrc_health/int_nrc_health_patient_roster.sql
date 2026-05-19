
  create or replace   view dw_dev.dev_jkizer.int_nrc_health_patient_roster
  
    
    
(
  
    "PATIENTNAMEGIVEN" COMMENT $$$$, 
  
    "PATIENTNAMEFAMILY" COMMENT $$$$, 
  
    "ADDRESSSTREET1" COMMENT $$$$, 
  
    "ADDRESSCITY" COMMENT $$$$, 
  
    "ADDRESSSTATE" COMMENT $$$$, 
  
    "ADDRESSPOSTALCODE" COMMENT $$$$, 
  
    "PHONEAREACITYCODE" COMMENT $$$$, 
  
    "PHONELOCALNUMBER" COMMENT $$$$, 
  
    "MRN" COMMENT $$$$, 
  
    "DATEOFBIRTH" COMMENT $$$$, 
  
    "ADMINISTRATIVESEX" COMMENT $$$$, 
  
    "PRIMARYLANGUAGE" COMMENT $$$$, 
  
    "RACE" COMMENT $$$$, 
  
    "ETHNICGROUP" COMMENT $$$$, 
  
    "MARITALSTATUS" COMMENT $$$$, 
  
    "EMAIL" COMMENT $$$$, 
  
    "PATIENTCLASS" COMMENT $$$$, 
  
    "FACILITYNAME" COMMENT $$$$, 
  
    "FACILITYNUMBER" COMMENT $$$$, 
  
    "VISITNUMBER" COMMENT $$$$, 
  
    "ADMITDATETIME" COMMENT $$$$, 
  
    "DISCHARGEDATETIME" COMMENT $$$$, 
  
    "ADMITSOURCE" COMMENT $$$$, 
  
    "DISCHARGESTATUS" COMMENT $$$$, 
  
    "LOCATIONCRITERIA" COMMENT $$$$, 
  
    "LOCATION" COMMENT $$$$, 
  
    "MSDRG" COMMENT $$$$, 
  
    "DIAGNOSISPRIMARYICD10" COMMENT $$$$, 
  
    "DIAGNOSIS2ICD10" COMMENT $$$$, 
  
    "DIAGNOSIS3ICD10" COMMENT $$$$, 
  
    "ISDECEASED" COMMENT $$$$, 
  
    "ICU" COMMENT $$$$, 
  
    "EDADMIT" COMMENT $$$$, 
  
    "PRIMARYPAYERID" COMMENT $$$$, 
  
    "PRIMARYPAYERNAME" COMMENT $$$$, 
  
    "ATTENDINGDOCTORNAMEGIVEN" COMMENT $$$$, 
  
    "ATTENDINGDOCTORNAMESECONDGIVEN" COMMENT $$$$, 
  
    "ATTENDINGDOCTORNAMEFAMILY" COMMENT $$$$, 
  
    "ATTENDINGDOCTORNAMESUFFIX" COMMENT $$$$, 
  
    "ATTENDINGDOCTORDEGREE" COMMENT $$$$, 
  
    "ATTENDINGDOCTORNPI" COMMENT $$$$, 
  
    "ATTENDINGDOCTORSPECIALTY" COMMENT $$$$, 
  
    "PROCEDUREPRIMARYCPT" COMMENT $$$$, 
  
    "PROCEDURE2CPT" COMMENT $$$$, 
  
    "PROCEDURE3CPT" COMMENT $$$$, 
  
    "HNUMIPDISCH" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

select
    -- 1: first name
    first_name as "PatientNameGiven",

    -- 2: last name
    last_name as "PatientNameFamily",

    -- 3: street address, max 60 chars, whitespace cleaned
    left(trim(regexp_replace(address_line_1, '[\r\n\t]', ' ')), 60) as "AddressStreet1",

    -- 4: city, max 42 chars, whitespace cleaned
    left(trim(regexp_replace(city, '[\r\n\t]', ' ')), 42) as "AddressCity",

    -- 5: USPS 2-letter uppercase
    case
        when length(trim(state)) = 2 then upper(trim(state))
        else null
    end as "AddressState",

    -- 6: 5-digit zip only
    case
        when length(regexp_replace(zip, '[^0-9]', '')) >= 5
            then left(regexp_replace(zip, '[^0-9]', ''), 5)
        else null
    end as "AddressPostalCode",

    -- 7: area code only (3 digits)
    case
        when length(regexp_replace(phone, '[^0-9]', '')) = 10
            then left(regexp_replace(phone, '[^0-9]', ''), 3)
        when length(regexp_replace(phone, '[^0-9]', '')) = 11
             and left(regexp_replace(phone, '[^0-9]', ''), 1) = '1'
            then substr(regexp_replace(phone, '[^0-9]', ''), 2, 3)
        else null
    end as "PhoneAreaCityCode",

    -- 8: local number only (7 digits, no area code)
    case
        when length(regexp_replace(phone, '[^0-9]', '')) = 10
            then substr(regexp_replace(phone, '[^0-9]', ''), 4, 7)
        when length(regexp_replace(phone, '[^0-9]', '')) = 11
             and left(regexp_replace(phone, '[^0-9]', ''), 1) = '1'
            then substr(regexp_replace(phone, '[^0-9]', ''), 5, 7)
        else null
    end as "PhoneLocalNumber",

    -- 9: internal patient ID used as medical record number
    ps.suvida_id as "MRN",

    -- 10: MM/DD/YYYY
    to_varchar(birth_date, 'MM/DD/YYYY') as "DateOfBirth",

    -- 11: M / F / O — maps Elation gender values to NRC Health spec; unknown maps to null
    case lower(ps.gender)
        when 'm'              then 'M'
        when 'f'              then 'F'
        when 'intersex/other' then 'O'
        else null
    end as "AdministrativeSex",

    -- 12: eng / spa
    case
        when lower(preferred_language) = 'english'    then 'eng'
        when lower(preferred_language) = 'spanish'    then 'spa'
        else null
    end as "PrimaryLanguage",

    -- 13: HL7 race code mapped from Elation race values
    case lower(ps.race)
        when 'asian'                                     then '2028-9'
        when 'white'                                     then '2106-3'
        when 'black or african american'                 then '2054-5'
        when 'native hawaiian or other pacific islander' then '2076-8'
        when 'american indian or alaska native'          then '1002-5'
        when 'declined to specify'                       then '0000-1'
        when 'no race specified'                         then '0000-0'
        else null
    end as "Race",

    -- 14: H = Hispanic or Latino, N = Not Hispanic or Latino, U = Unknown/declined
    case lower(ps.ethnicity)
        when 'hispanic or latino'     then 'H'
        when 'not hispanic or latino' then 'N'
        when 'declined to specify'    then 'U'
        when 'no ethnicity specified' then 'U'
        else 'U'
    end as "EthnicGroup",

    -- 15: all marital_status values are currently null in source data
    null as "MaritalStatus",

    -- 16: email address
    email as "Email",

    -- 17: visit/encounter type
    pe.encounter_type as "PatientClass",

    -- 18-19: location name from Elation; no facility number available
    -- TODO: NRC Health requires a 6-digit CMS Certification Number (CCN). Confirm which CCN maps to each Suvida location before populating.
    elation_location_name as "FacilityName",
    null as "FacilityNumber",

    -- 20: surrogate key for the encounter, used as visit identifier
    pe.encounter_skey as "VisitNumber",

    -- 21-22: YYYYMMDDHHMMSS; outpatient has no separate discharge time
    -- TODO: Confirm with NRC Health whether outpatient same-day visits should use AdmitDateTime here, or if null is acceptable.
    -- TODO: Format string uses 'HH' (12-hour clock), which silently produces wrong hours for any encounter after 12:59 PM.
    --       Change 'YYYYMMDDHHMMSS' to 'YYYYMMDDHH24MMSS' to use 24-hour time.
    to_varchar(pe.encounter_datetime, 'YYYYMMDDHHMMSS') as "AdmitDateTime",
    null as "DischargeDateTime",

    -- 23-24: not applicable for outpatient
    null as "AdmitSource",
    null as "DischargeStatus",

    -- 25-26: internal site code + patient-facing name
    ps.location_name as "LocationCriteria",
    elation_location_name as "Location",

    -- 27-30: inpatient-specific, null for primary care
    null as "MSDRG",
    null as "DiagnosisPrimaryICD10",
    null as "Diagnosis2ICD10",
    null as "Diagnosis3ICD10",

    -- 31-33: deceased hardcoded N (living patients only); ICU and ED not applicable for primary care
    'N' as "IsDeceased",
    null as "ICU",
    null as "EDAdmit",

    -- 34-35: patient's insurance plan code and name from current payer assignment
    ps.payer_plan_code as "PrimaryPayerID",
    ps.payer_plan_name as "PrimaryPayerName",

    -- 36-42: attending provider
    dp.user_first_name as "AttendingDoctorNameGiven",
    null as "AttendingDoctorNameSecondGiven",
    dp.user_last_name as "AttendingDoctorNameFamily",
    null as "AttendingDoctorNameSuffix",
    null as "AttendingDoctorDegree",
    provider_npi as "AttendingDoctorNPI",
    dp.specialty_desc as "AttendingDoctorSpecialty",

    -- 43-45: CPT codes not currently available
    null as "ProcedurePrimaryCPT",
    null as "Procedure2CPT",
    null as "Procedure3CPT",

    -- 46: inpatient discharge count, not applicable
    null as "HNumIPDisch"

from dw_dev.dev_jkizer.patient_encounter pe
join dw_dev.dev_jkizer.patient_summary ps
    on pe.suvida_id = ps.suvida_id
left join dw_dev.dev_jkizer.dim_provider dp
    on ps.provider_npi = dp.npi
where pe.encounter_type = 'clinical_encounter'
    and pe.encounter_date >= dateadd(day, -7, current_date)
    and pe.encounter_date < current_date
  );

