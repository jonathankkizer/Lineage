select
    measure_year::int as measure_year,
    payer_name,
    measure_name,
    nullif(trim(star_2), '')::decimal(5,4) as star_2,
    nullif(trim(star_3), '')::decimal(5,4) as star_3,
    nullif(trim(star_4), '')::decimal(5,4) as star_4,
    nullif(trim(star_4_5), '')::decimal(5,4) as star_4_5,
    nullif(trim(star_5), '')::decimal(5,4) as star_5,
    nullif(trim(star_6), '')::decimal(5,4) as star_6
from dw_dev.dev_jkizer_source.star_cutpoints_eoy