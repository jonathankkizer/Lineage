
  
    

create or replace transient table dw_dev.dev_jkizer.fct_referral
    copy grants
    
    
    as (with referrals as (
    select
        siw.suvida_id,
        ref_o.*,
        initcap(regexp_replace(
            regexp_substr(
                ref_o.clinical_reason, 
                'Specialty Type\s*([^\n\r]*)', 1, 1, 'e'
                ),
            '[^a-zA-Z ]', ''))
        as imputed_specialty_type, -- imputed specialty type from clinical reason text
    from dw_dev.dev_jkizer_staging.stg_elation_referral_order ref_o
    left join dw_dev.dev_jkizer.suvida_id_walk siw
        on ref_o.elation_id = siw.member_id
        and 'Elation' = siw.source
), combined_specialty as (
    select *,
        nullif(coalesce(recipient_specialty, 
                regexp_replace(imputed_specialty_type, '[[:space:][:cntrl:]]+', '')
        ), '') as source_specialty_type,
    from referrals r    
), referral_diagnosis as (
    select 
        referral_id,
        listagg(distinct code, ' | ') as referral_icd_list,
        listagg(distinct code_description, ' | ') as referral_icd_description_list,
    from dw_dev.dev_jkizer_staging.stg_elation_referral_order_diagnosis rod
    left join dw_dev.dev_jkizer_staging.stg_elation_icd10 icd 
        on rod.icd_10_code_id = icd.icd10_id
        and icd._idx = 1
    group by all
)
select 
    cs.* exclude (source_specialty_type, imputed_specialty_type),
    st.mapped_specialty_type as specialty_type,
    rd.referral_icd_list,
    rd.referral_icd_description_list,
from combined_specialty cs
left join dw_dev.dev_jkizer_source.map_referral_specialty_types st 
    on cs.source_specialty_type = st.source_specialty_type
left join referral_diagnosis rd 
    on cs.referral_id = rd.referral_id
    )
;


  