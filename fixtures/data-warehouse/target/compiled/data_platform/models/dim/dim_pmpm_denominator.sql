with data as (
    select 
        fm.financial_member_month, 
        pca.location_name as location_name,
        financial_source, 
        count(distinct(financial_membership_skey)) as static_member_month_location_financial_source_denominator,
        sum(pr.revenue) as revenue,
        sum(pr.projection_adjusted_revenue) as projection_adjusted_revenue,
    from dw_dev.dev_jkizer.patient_financial_membership fm
    left join dw_dev.dev_jkizer.patient_care_assignment pca 
        on pca.suvida_id =  fm.suvida_id
        and pca.care_assignment_month = fm.financial_member_month
    left join dw_dev.dev_jkizer.patient_revenue pr 
        on fm.suvida_id = pr.suvida_id 
        and fm.financial_member_month = pr.mmr_month 
    where financial_member_month_ind = 1 
    group by all 
)

select 
    md5(cast(coalesce(cast(financial_member_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(financial_source as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as skey, 
    *
from data