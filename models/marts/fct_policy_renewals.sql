{{
    config(
        materialized='incremental',
        unique_key='renewal_id'
    )
}}

with policy_terms as (
    select
        policy_id,
        start_date,
        end_date,
        policyholder_id
    from {{ ref('dim_policy') }}
),

renewals as (
    select
        {{ dbt_utils.generate_surrogate_key(['p1.policy_id', 'p1.start_date']) }} as renewal_id,
        p1.policy_id,
        p1.policyholder_id,
        p1.end_date as original_expiration,
        p2.start_date as renewal_date,
        datediff('day', p1.end_date, p2.start_date) as days_gap,
        case 
            when p2.policy_id is not null then true 
            else false 
        end as was_renewed
    from policy_terms p1
    left join policy_terms p2 
        on p1.policyholder_id = p2.policyholder_id
        and p2.start_date between p1.end_date and dateadd('day', 30, p1.end_date)
        and p1.policy_id != p2.policy_id
)

select * from renewals
