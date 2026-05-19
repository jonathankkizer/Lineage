with cte_order as (
    select 
     elation_id,
     order_id,
     order_type,
     practice_id,
     date_for_test,
     resolution_state,
     prescriber_user_id,
     clinical_reason,
     icd10_code,
     test_name,
     test_score,
     allergies,
     b_blocker,
     test_company_name,
     creation_date,
     creation_date_time,
     created_by_user_id,
     signed_date,
     signed_by_user_id,
     row_number() over(partition by elation_id, order_id, icd10_code order by hdb_last_sync desc) as rownum
    from dw_dev.dev_jkizer_staging.stg_elation_misc_order 
    where is_deleted = 'False' 
    and signed_by_user_id is not null
)
select 
    siw.suvida_id,
     co.elation_id,
     co.order_id,
     co.order_type,
     co.practice_id,
     co.date_for_test,
     co.resolution_state,
     co.prescriber_user_id,
     co.clinical_reason,
     co.test_name,
     co.test_score,
     co.allergies,
     co.b_blocker,
     co.test_company_name,
     co.creation_date,
     co.creation_date_time,
     co.created_by_user_id,
     co.signed_date,
     co.signed_by_user_id,
     eu.user_name as signed_by,
     listagg(co.icd10_code) as diagnosis_codes 
from cte_order co 
left join dw_dev.dev_jkizer_staging.stg_elation_user eu 
    on co.signed_by_user_id = eu.user_id 
left join dw_dev.dev_jkizer.suvida_id_walk siw
    on co.elation_id = siw.member_id
	and siw.source = 'Elation'
where co.rownum = '1'
group by
 siw.suvida_id,
     co.elation_id,
     co.order_id,
     co.order_type,
     co.practice_id,
     co.date_for_test,
     co.resolution_state,
     co.prescriber_user_id,
     co.clinical_reason,
     co.test_name,
     co.test_score,
     co.allergies,
     co.b_blocker,
     co.test_company_name,
     co.creation_date,
     co.creation_date_time,
     co.created_by_user_id,
     co.signed_date,
     co.signed_by_user_id,
     signed_by