

with suspects as (
    select 
        suvida_id,
        elation_id,
        mdportals_id,
        next_careteam_appt_date,
        compendium_last_updated,
        date_created,
        row_number() over (partition by suvida_id, elation_id, mdportals_id order by date_created desc) as _idx
    from source_prod.mdportals.suspects
),

latest_suspects as (
    select *
    from suspects
    where _idx = 1
)

select distinct
    ps.suvida_id,
    ps.elation_id,
    mpt.id as mdportals_id,
    sus.compendium_last_updated,
    ps.next_careteam_appt_date
from dw_dev.dev_jkizer.patient_summary ps
inner join source_prod.mdportals.patient mpt
    on ps.elation_id = mpt.elation_id
left join latest_suspects sus
    on ps.suvida_id = sus.suvida_id
where
    to_date(ps.last_pcp_appt_date) between dateadd(day, -7, current_date()) and current_date() and
    (
        ps.next_careteam_appt_date <> sus.next_careteam_appt_date or 
        sus.date_created <= dateadd(day, -14, current_date())
    )