
    
    

with all_values as (

    select
        input_output_match_rate as value_field,
        count(*) as n_records

    from dw_dev.dev_jkizer.suvida_id_process_stats
    group by input_output_match_rate

)

select *
from all_values
where value_field not in (
    1.0
)


