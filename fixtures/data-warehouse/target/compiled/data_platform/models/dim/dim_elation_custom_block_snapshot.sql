-- Table grain is one row per version of question and answering pairing per custom block/template 
-- There can be multiple versions of a custon block with multiple answers per questions, this table captures all possibilities 

----- Contains the different versions of a custom block


with base as (
  select 
    custom_block_snapshot_id,
    custom_block_id,
    created_at, 
    edited_at,
    custom_block_snapshot[0]:dataSchema:properties as properties
  from dw_dev.dev_jkizer_staging.stg_elation_vn2_custom_block_snapshot
),

-- flatten properties
properties_flat as (
  select
    custom_block_snapshot_id,
    custom_block_id,
    created_at, 
    edited_at,
    property.key::string as question_field_name,
    property.value:title::string as question_title,
    property.value:type::string as question_type,
    property.value:uniqueItems::boolean as unique_items,
    property.value:oneOf as single_select_options,
    property.value:items:oneOf as multi_select_options
  from base,
  lateral flatten(input => base.properties) property
),

-- for string type with oneof (single select questions) - show all options
single_select_questions as (
  select
    custom_block_snapshot_id,
    custom_block_id,
    created_at, 
    edited_at,
    pf.question_field_name,
    pf.question_title,
    pf.question_type,
    opt.value:const::string as answer_value,
    opt.value:title::string as answer_title
  from properties_flat pf
  cross join lateral flatten(input => pf.single_select_options, outer => true) opt
  where pf.question_type = 'string' 
    and pf.single_select_options is not null
),

-- for array type with items.oneof (multi-select questions) - show all options
multi_select_questions as (
  select
    custom_block_snapshot_id,
    custom_block_id,
    created_at, 
    edited_at,
    pf.question_field_name,
    pf.question_title,
    pf.question_type,
    opt.value:const::string as answer_value,
    opt.value:title::string as answer_title
  from properties_flat pf
  cross join lateral flatten(input => pf.multi_select_options, outer => true) opt
  where pf.question_type = 'array'
    and pf.multi_select_options is not null
),

-- for simple fields (no options - just string/date inputs)
simple_fields as (
  select
    custom_block_snapshot_id,
    custom_block_id,
    created_at, 
    edited_at,
    question_field_name,
    question_title,
    question_type,
    null as answer_value,
    null as answer_title
  from properties_flat
  where question_type not in ('array')
    and single_select_options is null
),

-- combine all results
combined as (
select 
    custom_block_snapshot_id,
    custom_block_id,
    question_field_name,
    question_title,
    question_type,
    answer_value,
    answer_title,
    created_at, 
    edited_at
from single_select_questions

union all

select 
    custom_block_snapshot_id,
    custom_block_id,
    question_field_name,
    question_title,
    question_type,
    answer_value,
    answer_title,
    created_at, 
    edited_at
from multi_select_questions

union all

select 
    custom_block_snapshot_id,
    custom_block_id,
    question_field_name,
    question_title,
    question_type,
    answer_value,
    answer_title,
    created_at, 
    edited_at
from simple_fields

order by custom_block_snapshot_id, custom_block_id, question_field_name, answer_value
) 

select 
md5(cast(coalesce(cast(custom_block_snapshot_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(custom_block_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(question_field_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(answer_value as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as custom_block_snapshot_skey,
*
from combined