
  
    

create or replace transient table dw_dev.dev_jkizer.dim_awell_care_flow
    copy grants
    
    
    as (--A care flow "definition_id" can have many versions. 
--For each version release, this table lists all tracks and the steps per track

with latest_v as (
    select 
        published_careflow_id,
        version_number
    from dw_dev.dev_jkizer_staging.stg_awell_published_careflows 
    qualify row_number() over (partition by definition_id order by version_number desc) = 1
)

select 
    pcf.published_careflow_id,
    pcf.definition_id,
    pcf.release_id,
    pcf.title,
    pcf.version_number,
    iff(latest_v.published_careflow_id is not null, true, false) as is_latest_version,
    tracks.track_name,
    count(distinct(steps.definition_id)) as ct_steps
from dw_dev.dev_jkizer_staging.stg_awell_published_careflows pcf
left join dw_dev.dev_jkizer_staging.stg_awell_care_flows care_flows 
    on care_flows.definition_id = pcf.definition_id
    and care_flows.release_id = pcf.release_id
left join dw_dev.dev_jkizer_staging.stg_awell_tracks tracks 
    on tracks.care_flow_definition_id = care_flows.definition_id
    and tracks.care_flow_id = care_flows.care_flow_id
left join dw_dev.dev_jkizer_staging.stg_awell_steps steps 
    on steps.care_flow_definition_id = care_flows.definition_id 
    and steps.care_flow_id = care_flows.care_flow_id
    and steps.track_id = tracks.track_id
left join latest_v 
    on latest_v.published_careflow_id = pcf.published_careflow_id 
    and latest_v.version_number = pcf.version_number
group by all
    )
;


  