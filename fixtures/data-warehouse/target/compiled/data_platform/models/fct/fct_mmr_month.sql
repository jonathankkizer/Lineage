with unioned_data as (
	select 
		*,
		null as payer_parent,
		null as payer_name,
		null as payer_contract,
	from dw_dev.dev_jkizer.fct_mmr_month_devoted

	union all

	select 
		*,
		null as payer_parent,
		null as payer_name,
		null as payer_contract,
	from dw_dev.dev_jkizer.fct_mmr_month_wellcare

	union all
	
	select 
		*, 
		null as payer_parent,
		null as payer_name,
		null as payer_contract,
	from dw_dev.dev_jkizer.fct_mmr_month_wellmed

	union all

	select *
	from dw_dev.dev_jkizer.fct_mmr_month_united

	union all

	select
		*,
		null as payer_parent,
		null as payer_name,
		null as payer_contract
	from dw_dev.dev_jkizer.fct_mmr_month_alignment
), age_category as (
    select
        ud.*,
        iff(datediff(year, birth_date, to_date(year(mmr_month) || '-01-31')) >= 65, '65+', '<65') as age_category
    from unioned_data ud
), deduplication as (
select
	ud.*,
	mrt.hcc_engine_raf_type_description,
	mrt.hcc_engine_raf_type,
	lpad(to_varchar(mrt.dual_benefit_code), 2, '0') as dual_benefit_code,
	dense_rank() over (partition by suvida_id order by mmr_month desc) as patient_mmr_rank,
	row_number() over (partition by suvida_id, mmr_month order by mmr_source desc) as suvida_id_mmr_rank,
	row_number() over (partition by coalesce(member_id, medicare_beneficiary_id), mmr_month order by mmr_source desc) as member_id_mbi_mmr_rank,
from age_category ud
left join dw_dev.dev_jkizer_source.map_raf_type mrt
	on ud.raf_type_code = mrt.raf_type_code
	and ud.age_category = mrt.age_category
)
select 
	*
from deduplication
where (suvida_id_mmr_rank = 1 or (suvida_id is null and member_id_mbi_mmr_rank = 1))