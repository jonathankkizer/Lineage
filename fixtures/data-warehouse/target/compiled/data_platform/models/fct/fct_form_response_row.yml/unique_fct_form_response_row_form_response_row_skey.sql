
    
    

select
    form_response_row_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_form_response_row
where form_response_row_skey is not null
group by form_response_row_skey
having count(*) > 1


