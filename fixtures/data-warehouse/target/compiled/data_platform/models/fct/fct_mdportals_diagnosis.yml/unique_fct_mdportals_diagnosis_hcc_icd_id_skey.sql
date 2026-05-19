
    
    

select
    hcc_icd_id_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_mdportals_diagnosis
where hcc_icd_id_skey is not null
group by hcc_icd_id_skey
having count(*) > 1


