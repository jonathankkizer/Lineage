
    
    

select
    zentake_response_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.zentake_response
where zentake_response_skey is not null
group by zentake_response_skey
having count(*) > 1


