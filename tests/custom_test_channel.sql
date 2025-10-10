{{
    config(
        severity='warn'
    )
}}

with invalid_channel_types as (
    select
        agency_id,
        channel_type
    from {{ ref('stg_agencies') }}
    where channel_type != 'Bad-channel'
)

select count(*) as invalid_count
from invalid_channel_types