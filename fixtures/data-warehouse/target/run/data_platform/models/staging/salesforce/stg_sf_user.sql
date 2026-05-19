
  create or replace   view dw_dev.dev_jkizer_staging.stg_sf_user
  
  copy grants
  
  
  as (
    select
	id as sf_user_id,
	Username as user_name,
	LastName as last_name,
	FirstName as first_name,
	Name as name,
	email as email,
	IsActive as is_active,
	date(LastLoginDate) as last_login_date,
	Team_Name__c as team_name
from airbyte_source_prod.salesforce_production.user
  );

