

-- Component: Patient vitals (latest height, weight, and BMI)
-- Extracted to provide most recent height/weight/BMI measurements per patient
-- Each vital is ranked independently to handle sporadic data population

with latest_vitals as (
    select
        suvida_id,
        height,
        height_units,
        weight,
        weight_units,
        bmi,
        document_datetime as vital_datetime,
        row_number() over (
            partition by suvida_id
            order by
                case when height is not null then 0 else 1 end,
                document_datetime desc
        ) as height_index,
        row_number() over (
            partition by suvida_id
            order by
                case when weight is not null then 0 else 1 end,
                document_datetime desc
        ) as weight_index,
        row_number() over (
            partition by suvida_id
            order by
                case when bmi is not null then 0 else 1 end,
                document_datetime desc
        ) as bmi_index
    from dw_dev.dev_jkizer.patient_vital
    where height is not null or weight is not null or bmi is not null
),

height_values as (
    select
        suvida_id,
        height as most_recent_height,
        height_units as most_recent_height_units,
        vital_datetime as most_recent_height_date
    from latest_vitals
    where height_index = 1 and height is not null
),

weight_values as (
    select
        suvida_id,
        weight as most_recent_weight,
        weight_units as most_recent_weight_units,
        vital_datetime as most_recent_weight_date
    from latest_vitals
    where weight_index = 1 and weight is not null
),

bmi_values as (
    select
        suvida_id,
        bmi as most_recent_bmi,
        vital_datetime as most_recent_bmi_date
    from latest_vitals
    where bmi_index = 1 and bmi is not null
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    hv.most_recent_height,
    hv.most_recent_height_units,
    hv.most_recent_height_date,
    wv.most_recent_weight,
    wv.most_recent_weight_units,
    wv.most_recent_weight_date,
    bv.most_recent_bmi,
    bv.most_recent_bmi_date
from all_patients ap
left join height_values hv on ap.suvida_id = hv.suvida_id
left join weight_values wv on ap.suvida_id = wv.suvida_id
left join bmi_values bv on ap.suvida_id = bv.suvida_id