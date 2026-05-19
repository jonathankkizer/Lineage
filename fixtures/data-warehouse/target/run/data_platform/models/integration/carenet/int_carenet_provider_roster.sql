
  create or replace   view dw_dev.dev_jkizer.int_carenet_provider_roster
  
    
    
(
  
    "EXTERNALID" COMMENT $$$$, 
  
    "FIRSTNAME" COMMENT $$$$, 
  
    "MIDDLENAME" COMMENT $$$$, 
  
    "LASTNAME" COMMENT $$$$, 
  
    "ADDRESS1" COMMENT $$$$, 
  
    "ADDRESS2" COMMENT $$$$, 
  
    "CITY" COMMENT $$$$, 
  
    "STATE" COMMENT $$$$, 
  
    "ZIP" COMMENT $$$$, 
  
    "PHONEFAX" COMMENT $$$$, 
  
    "PHONEWORK" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

select distinct
	npi as ExternalId, 
	user_first_name as FirstName,
	null as MiddleName,
	user_last_name as LastName,
	null as Address1,
	null as Address2,
	null as City,
	null as State,
	null as Zip,
	null as PhoneFax,
	null as PhoneWork
from dw_dev.dev_jkizer.dim_provider
  );

