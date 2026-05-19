
  
    

create or replace transient table dw_dev.dev_jkizer.fct_mdportals_diagnosis
    copy grants
    
    
    as (with combined as (
    select *, 
    cast(regexp_replace(hcc, '[^0-9]', '') as int) as hcc_code,
    'confirmed' as code_type
    from dw_dev.dev_jkizer_staging.stg_md_portals_confirmed_codes   
    where hcc != ''

    union all 

    select *, 
    cast(regexp_replace(hcc, '[^0-9]', '') as int) as hcc_code,
    'denied' as code_type
    from dw_dev.dev_jkizer_staging.stg_md_portals_denied_codes  

    union all 

    select *,
    cast(regexp_replace(hcc, '[^0-9]', '') as int) as hcc_code,
    'known' as code_type 
    from dw_dev.dev_jkizer_staging.stg_md_portals_known_codes   

    union all 

    select *,
    cast(regexp_replace(hcc, '[^0-9]', '') as int) as hcc_code,
    'newly_identified' as code_type 
    from dw_dev.dev_jkizer_staging.stg_md_portals_newly_identified_codes  
)

select 
    md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icd_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(coalesce(combined.hcc_code,1) as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as hcc_icd_id_skey,
    siw.suvida_id, 
    replace(icd_code, '.', '') as icd_10_code,
    code_type as mdportal_code_type, 
    combined.hcc_code,
    hl.hcc_community_factor as hcc_v24_community_non_dual_weight,
    v28.hcc_community_factor as hcc_v28_community_non_dual_weight,
    compendium_last_updated_datetime, 
    icd_last_updated 
from combined 
inner join dw_dev.dev_jkizer.suvida_id_walk siw 
    on siw.member_id = combined.elation_id and siw.source = 'Elation'
left join dw_dev.dev_jkizer_staging.stg_elation_hcc_lookup hl 
    on cast(hl.hcc_code as int) = combined.hcc_code and hl.version = '2023' 
left join dw_dev.dev_jkizer_staging.stg_elation_hcc_lookup v28 
    on cast(v28.hcc_code as int) = combined.hcc_code and v28.version = '2024' 
where icd_10_code is not null
qualify row_number() over (partition by suvida_id, combined.hcc_code, icd_code order by icd_last_updated desc) = 1
    )
;


  