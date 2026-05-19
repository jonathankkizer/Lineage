with multi_elation as ( -- find suvida ids with multiple elation accounts
	select 
		suvida_id, 
		sum(case when source = 'Elation' then 1 else 0 end) as num_elation_accounts
	from dw_dev.dev_jkizer.suvida_id_walk 
	group by suvida_id 
	having sum(case when source = 'Elation' then 1 else 0 end) > 1
), multi_devoted as (
	select 
		suvida_id, 
		sum(case when source = 'Devoted' then 1 else 0 end) as num_devoted_accounts
	from dw_dev.dev_jkizer.suvida_id_walk 
	group by suvida_id 
	having sum(case when source = 'Devoted' then 1 else 0 end) > 1
), multi_wellcare as (
	select 
		suvida_id, 
		sum(case when source = 'Wellcare/Centene' then 1 else 0 end) as num_wellcare_accounts
	from dw_dev.dev_jkizer.suvida_id_walk 
	group by suvida_id 
	having sum(case when source = 'Wellcare/Centene' then 1 else 0 end) > 1
), multi_wellmed as (
	select 
		suvida_id, 
		sum(case when source = 'UHG/Wellmed' then 1 else 0 end) as num_wellmed_accounts
	from dw_dev.dev_jkizer.suvida_id_walk 
	group by suvida_id 
	having sum(case when source = 'UHG/Wellmed' then 1 else 0 end) > 1
), multi_wellcare_az as (
	select
		suvida_id,
		sum(case when source = 'Wellcare AZ' then 1 else 0 end) as num_wellcare_az_accounts
	from dw_dev.dev_jkizer.suvida_id_walk
	group by suvida_id
	having sum(case when source = 'Wellcare AZ' then 1 else 0 end) > 1
), multi_salesforce as (
select
	suvida_id,
	sum(case when source = 'SalesForce' then 1 else 0 end) as num_salesforce_accounts
from dw_dev.dev_jkizer.suvida_id_walk
group by suvida_id
having sum(case when source = 'SalesForce' then 1 else 0 end) > 1
)
select 
	count(*) as num_entities, -- total number of input records to suvida id process
	sum(case when siw.suvida_id is not null then 1 else 0 end) as num_matched_entities, -- total number of outputs to suvida id process should match input
	round(sum(case when siw.suvida_id is not null then 1.0 else 0.0 end) / count(*), 1) as input_output_match_rate,
	count(distinct siw.suvida_id) as num_distinct_people, -- distinct "entities" found in input will be less than input, because we expect a patient to generally have one payer record and one elation record
	cast(count(*) as decimal) / count(distinct siw.suvida_id)*1.0 as avg_entities_per_person, -- should ideally be = 2 however, not all EMR patients will be attributed, and so will likely hover around 1.7-1.95 patients can have more than 2 if they jump payers
	count(distinct me.suvida_id) as person_multi_elation_accounts_count, -- should try to minimize this number, either via consolidating true Elation duplicates, or removing false matches in suvida id process,
	count(distinct de.suvida_id) as person_multi_devoted_accounts_count, -- # should be low but may not be 0 if member gets a new ID from payer
	count(distinct wce.suvida_id) as person_multi_wellcare_accounts_count, -- # should be low but may not be 0 if member gets a new ID from payer
	count(distinct wme.suvida_id) as person_multi_wellmed_accounts_count, -- # should be low but may not be 0 if member gets a new ID from payer
	count(distinct waze.suvida_id) as person_multi_wellcare_az_accounts_count, -- # should be low but may not be 0 if member gets a new ID from payer
	count(distinct se.suvida_id) as person_multi_salesforce_accounts_count, -- # should be low but may not be 0 if member gets a new ID from payer
	sum(case when ipi.source = 'Elation' then 1 else 0 end) as num_elation_accounts,
	sum(case when ipi.source = 'UHG/Wellmed' then 1 else 0 end) as num_wellmed_accounts,
	sum(case when ipi.source = 'Devoted' then 1 else 0 end) as num_devoted_accounts,
	sum(case when ipi.source = 'Wellcare/Centene' then 1 else 0 end) as num_wellcare_accounts,
	sum(case when ipi.source = 'Wellcare AZ' then 1 else 0 end) as num_wellcare_az_accounts,
	sum(case when ipi.source = 'SalesForce' then 1 else 0 end) as num_salesforce_accounts
from dw_dev.dev_jkizer.int_suvida_id_input ipi 
left join dw_dev.dev_jkizer.suvida_id_walk siw 
	on ipi.source = siw.source 
	and ipi.member_id = siw.member_id
left join multi_elation me 
	on siw.suvida_id = me.suvida_id
left join multi_devoted de 
	on siw.suvida_id = de.suvida_id
left join multi_wellcare wce 
	on siw.suvida_id = wce.suvida_id
left join multi_wellmed wme
	on siw.suvida_id = wme.suvida_id
left join multi_wellcare_az waze
	on siw.suvida_id = waze.suvida_id
left join multi_salesforce se
	on siw.suvida_id = se.suvida_id