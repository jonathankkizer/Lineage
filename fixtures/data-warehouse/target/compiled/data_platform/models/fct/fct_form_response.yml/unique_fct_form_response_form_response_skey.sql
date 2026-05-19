
    
    

select
    form_response_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_form_response
where form_response_skey is not null
group by form_response_skey
having count(*) > 1


