{% test is_valid_channel(model) %}


with invalid_channel_types as (
    select
           channel_type
    from {{ model }}
    where channel_type != 'Bad-channel'
)

select channel_type
from invalid_channel_types

{% endtest %}

