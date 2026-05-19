with proc_flags as (
	select
		encounter_skey,
		max(is_awv) as is_awv,
		max(is_rd) as is_rd,
		max(is_ultrasound) as is_ultrasound,
		max(is_xray) as is_xray,
		max(is_pcp) as is_pcp,
		max(is_mh) as is_mh,
		max(is_pt) as is_pt,
		max(is_pharmacy) as is_pharmacy,
		max(is_guia) as is_guia,
		max(is_rn) as is_rn,
		listagg(p.cpt_code, ' | ') as cpt_codes,
	from dw_dev.dev_jkizer.fct_procedure p
	group by encounter_skey
)
select
	fe.*,
	pf.cpt_codes,
	pf.is_awv,
	pf.is_rd,
	pf.is_ultrasound,
	pf.is_xray,
	pf.is_pcp,
	pf.is_mh,
	pf.is_pt,
	pf.is_pharmacy,
	pf.is_guia,
	pf.is_rn,
from dw_dev.dev_jkizer.fct_encounter fe
left join proc_flags pf
	on fe.encounter_skey = pf.encounter_skey