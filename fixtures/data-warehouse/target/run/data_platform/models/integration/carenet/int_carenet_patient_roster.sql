
  create or replace   view dw_dev.dev_jkizer.int_carenet_patient_roster
  
    
    
(
  
    "ACTIONCODE" COMMENT $$$$, 
  
    "EXTERNALDBCODE" COMMENT $$$$, 
  
    "EXTERNALID" COMMENT $$$$, 
  
    "MEMBERID" COMMENT $$$$, 
  
    "FIRSTNAME" COMMENT $$$$, 
  
    "MIDDLENAME" COMMENT $$$$, 
  
    "LASTNAME" COMMENT $$$$, 
  
    "ADDRESS1" COMMENT $$$$, 
  
    "ADDRESS2" COMMENT $$$$, 
  
    "CITY" COMMENT $$$$, 
  
    "STATE" COMMENT $$$$, 
  
    "ZIP" COMMENT $$$$, 
  
    "SOCSEC" COMMENT $$$$, 
  
    "DOB" COMMENT $$$$, 
  
    "GENDER" COMMENT $$$$, 
  
    "PHONEHOME" COMMENT $$$$, 
  
    "PHONEHOMEEXT" COMMENT $$$$, 
  
    "PHONEWORK" COMMENT $$$$, 
  
    "PHONEWORKEXT" COMMENT $$$$, 
  
    "PHONECELL" COMMENT $$$$, 
  
    "PHONEBEEPER" COMMENT $$$$, 
  
    "PHONEFAX" COMMENT $$$$, 
  
    "PAGERPIN" COMMENT $$$$, 
  
    "EMAIL" COMMENT $$$$, 
  
    "PERSONALURL" COMMENT $$$$, 
  
    "INSURANCE" COMMENT $$$$, 
  
    "PLANCODE" COMMENT $$$$, 
  
    "EMPLOYERGROUP" COMMENT $$$$, 
  
    "MARRIEDSTATUS" COMMENT $$$$, 
  
    "LANGUAGEDESC" COMMENT $$$$, 
  
    "PROVIDERID" COMMENT $$$$, 
  
    "MEDICARECOVERAGE" COMMENT $$$$, 
  
    "ORGNAME" COMMENT $$$$, 
  
    "NOTES" COMMENT $$$$, 
  
    "MEDICALRECORDID" COMMENT $$$$, 
  
    "APPROVECOMMUNICATE" COMMENT $$$$, 
  
    "PREFERREDCOMTYPE" COMMENT $$$$, 
  
    "CONSENTPHI" COMMENT $$$$, 
  
    "AUTHORIZEDPHILIST" COMMENT $$$$, 
  
    "HOME" COMMENT $$$$, 
  
    "PREFERREDPHARMACYNAME" COMMENT $$$$, 
  
    "PREFERREDPHARMACYADDRESS" COMMENT $$$$, 
  
    "PREFERREDPHARMACYPHONENUMBER" COMMENT $$$$, 
  
    "PREFERREDFULLNAME" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

select
	'R' as ActionCode,
	null as ExternalDBCode,
	suvida_id as ExternalId,
	elation_id as MemberId,
	first_name as FirstName,
	null as MiddleName,
	last_name as LastName,
	address_line_1 as Address1,
	address_line_2 as Address2,
	city as City,
	state AS State,
	zip AS Zip,
	null as SocSec,
	to_char(birth_date, 'YYYY-MM-DD') as DOB,
	null as Gender,
	phone as PhoneHome,
	null as PhoneHomeExt,
	null as PhoneWork,
	null as PhoneWorkExt,
	null as PhoneCell,
	null as PhoneBeeper,
	null as PhoneFax,
	null as PagerPIN,
	null as Email,
	elation_patient_url as PersonalURL,
	elation_insurance_name as Insurance,
	payer_plan_code as PlanCode,
	null as EmployerGroup,
	null as MarriedStatus,
	preferred_language as LanguageDesc,
	provider_npi as ProviderId,
	case when elation_insurance_name ilike ('%medicare%') then 'Y' else 'N' end as MedicareCoverage,
	null as OrgName,
	null as Notes, 
	null as MedicalRecordId,
	null as ApproveCommunicate,
	null as PreferredComType,
	consent_to_receive_phi as ConsentPHI,
	consent_receive_phi_list as AuthorizedPHIList,
	location_name as Home,
	pref_pharmacy1_name as PreferredPharmacyName,
	pref_pharmacy1_address as PreferredPharmacyAddress,
	pref_pharmacy1_phone as PreferredPharmacyPhoneNumber,
	full_name as PreferredFullName
FROM dw_dev.dev_jkizer.patient_summary
  );

