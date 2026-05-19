
  create or replace   view dw_dev.dev_jkizer_staging.stg_sf_campaign_member
  
  copy grants
  
  
  as (
    select
    accountid, 
    campaignid, 
    city,
    companyoraccount,
    contactid, 
    contact_language_preference__c, 
    contact_rating__c, 
    contact_stage__c, 
    contact_type__c, 
    country,
    createdbyid, 
    createddate, 
    description, 
    donotcall,
    email,
    fax,
    firstname,
    firstrespondeddate, 
    hasoptedoutofemail, 
    hasoptedoutoffax, 
    hasresponded, 
    health_plan_current__c, 
    home_phone__c, 
    id, 
    isdeleted, 
    lastmodifiedbyid, 
    lastmodifieddate, 
    lastname, 
    last_activity_date__c, 
    leadid, 
    leadorcontactid, 
    leadorcontactownerid, 
    leadsource,
    lead_status__c, 
    lead_type__c, 
    mobilephone, 
    name,
    phone, 
    postalcode, 
    preferred_suvida_location__c, 
    salutation, 
    source_prospect_patient__c, 
    state, 
    status, 
    street, 
    suvidacreatedby__c, 
    systemmodstamp,
    title,
    type
from airbyte_source_prod.salesforce_production.campaignmember
  );

