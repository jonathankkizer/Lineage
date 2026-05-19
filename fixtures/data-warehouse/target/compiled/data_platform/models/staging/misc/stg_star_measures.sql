select
    measure_name,
    measure_abbreviation,
    description,
    measure_type,
    is_inverted = 'TRUE' as is_inverted,
    measure_display_name
from dw_dev.dev_jkizer_source.star_measures