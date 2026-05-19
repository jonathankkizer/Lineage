

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