with cte_mr_measure as (
    select
        fp.suvida_id,
        1 as suvida_numerator,
        1 as suvida_denominator,
        0 as pending_numerator,
        max(fp.encounter_date) as evidence_date,
        listagg(fp.cpt_code, ' | ')  as evidence_desc,
        year(max(fp.encounter_date)) as evidence_year
    from dw_dev.dev_jkizer.fct_procedure fp
    where fp.cpt_code IN ('1159F', '1160F')
    and year(fp.encounter_date) = year(current_date())
    group by fp.suvida_id
    having count(distinct fp.cpt_code) = 2 -- Ensures both codes exist
    qualify rank() over (partition by fp.suvida_id order by max(fp.encounter_date) desc) = 1
)
select
    *,
    'Care for Older Adults - Medication Review' as quality_measure
from cte_mr_measure