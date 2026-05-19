
  
    

create or replace transient table dw_dev.dev_jkizer.patient_psychological_history
    copy grants
    
    
    as (with mental_health_scores as (
    select
        eph.patient_id,
        eph.source,
        iff(eph.history_value like '%Score:%', 
            trim(substr(eph.history_value,1,charindex(' Score: ',eph.history_value))), 
            null) as score_type,
	    try_to_number(iff(eph.history_value like '%Score:%',
            substr(eph.history_value,charindex('Score: ',eph.history_value)+7,2),
            null)) as score_value,
        eph.created_by_user_id,
        date(eph.creation_datetime) as creation_date,
        eph.creation_datetime,
        eph.last_modified_datetime
    from dw_dev.dev_jkizer_staging.stg_elation_patient_history eph
    where history_type = 'Psychological' 
    and deletion_datetime is null
)

select
    mhs.patient_id,
    siw.suvida_id,
    mhs.score_type,
    mhs.score_value,
    mhs.created_by_user_id,
    mhs.creation_date,
    mhs.creation_datetime,
    mhs.last_modified_datetime
from mental_health_scores mhs
left join dw_dev.dev_jkizer.suvida_id_walk siw
    on to_varchar(mhs.patient_id) = siw.member_id
    and mhs.source = siw.source
where score_value is not null
    )
;


  