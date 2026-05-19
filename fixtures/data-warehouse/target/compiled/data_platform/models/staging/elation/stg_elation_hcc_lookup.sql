select distinct 
	VERSION as version, 
	HCC_CODE as hcc_code, 
	HCC_LABEL as hcc_label, 
	HCC_COMMUNITY_FACTOR as hcc_community_factor, 
	HCC_INSTITUTIONAL_FACTOR as hcc_institutional_factor
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_problem_code_hcc