{% test is_valid_channel(model, column_name) %}


with invalid_channel_types as (
    select
          {{ column_name }} as channel_type
    from {{ model }}
    where  {{ column_name }} != 'Bad-channel'
)

select {{ column_name }}
from invalid_channel_types

{% endtest %}

