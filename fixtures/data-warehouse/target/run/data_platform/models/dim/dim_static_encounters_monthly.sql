
  
    

create or replace transient table dw_dev.dev_jkizer.dim_static_encounters_monthly
    copy grants
    
    
    as (with all_combinations as (
    -- Get all month x provider/location combinations
    select 
        ds.date_month,
        dim.location_name,
        dim.user_id,
        dim.provider_name
    from dw_dev.dev_jkizer.dim_date ds
    cross join dw_dev.dev_jkizer.dim_provider dim
    where ds.date_month between '2023-01-01' and current_date
),

data as (
    select 
        ac.date_month,
        ac.user_id, 
        ac.provider_name,
        ac.location_name,
        count(distinct fct.encounter_skey) as monthly_encounters
    from all_combinations ac
    left join dw_dev.dev_jkizer.fct_encounter fct
        on ac.date_month = date_trunc('month', fct.encounter_date)
        and ac.user_id = fct.signed_by_user_id
        and fct.encounter_type = 'clinical_encounter'
    group by all
)

select 
    md5(cast(coalesce(cast(date_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(user_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(location_name as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as skey, 
    * 
from data
    )
;


  