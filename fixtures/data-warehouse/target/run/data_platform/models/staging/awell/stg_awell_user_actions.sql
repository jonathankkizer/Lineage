
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_user_actions
  
  copy grants
  
  
  as (
    SELECT
        a.id as activity_id,
        a.care_flow_id,
        a.track_id,
        a.action_definition_id,
        to_timestamp(a.completion_date) as user_action_completion_date,
        a.indirect_object_name as user_team_name,
        sub.value:action::string AS sub_action,
        sub.value:subject.name::string AS user_email,
        sub.value:date::datetime as user_action_date,
        row_number() over (partition by a.id, sub.value:action::string order by sub.value:date::datetime desc) as user_action_index,
    FROM
        source_prod.awell.activities a,
        TABLE(FLATTEN(INPUT => PARSE_JSON(a.sub_activities))) sub
    WHERE
        a.sub_activities IS NOT NULL and a.object_type in ('form', 'message')
        AND sub.value:action::string IN ('read', 'submitted')
  );

