

with hosted_share as (
    select
        rod.uq_referral_order_dx,
        rod.referral_diagnosis_id,
        rod.icd_10_code_id,
        icd.code as icd_10_code,
        icd.code_description as icd_10_code_description,
        rod.referral_id,
        rod.warehouse_id,
        rod.is_deleted,
        rod.hdb_last_sync_datetime,
        'hosted_share' as _data_source
    from dw_dev.dev_jkizer_staging.stg_elation_referral_order_diagnosis rod
    left join dw_dev.dev_jkizer_staging.stg_elation_icd10 icd
        on rod.icd_10_code_id = icd.icd10_id
        and icd._idx = 1
), relay_referral_ids_for_today as (
    select referral_id
    from dw_dev.dev_jkizer.int_elation_referral
    where _data_source = 'relay'
), relay_path as (
    select
        to_varchar(rd.referral_id) || ':' || rd.icd_10_code as uq_referral_order_dx,
        cast(null as number) as referral_diagnosis_id,
        icd.icd10_id as icd_10_code_id,
        rd.icd_10_code,
        coalesce(icd.code_description, rd.icd_10_code_description) as icd_10_code_description,
        rd.referral_id,
        cast(null as number) as warehouse_id,
        cast(0 as boolean) as is_deleted,
        rd._airbyte_extracted_at as hdb_last_sync_datetime,
        'relay' as _data_source
    from dw_dev.dev_jkizer_staging.stg_elation_relay_referral_order_diagnosis rd
    inner join relay_referral_ids_for_today rt on rt.referral_id = rd.referral_id
    left join dw_dev.dev_jkizer_staging.stg_elation_icd10 icd
        on rd.icd_10_code = icd.code
        and icd._idx = 1
    where rd._idx = 1
), combined as (
    select * from hosted_share
    union all
    select * from relay_path
)
select *
from combined
qualify row_number() over (
    partition by referral_id, coalesce(to_varchar(icd_10_code_id), icd_10_code)
    order by case when _data_source = 'relay' then 1 else 2 end
) = 1