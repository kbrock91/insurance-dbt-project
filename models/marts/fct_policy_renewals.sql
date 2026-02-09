{{
    config(
        materialized='incremental_snapshot_merge',
        unique_key='renewal_id'
    )
}}

-- Policy renewal fact table tracking renewal rates and retention
-- Error: dbt1000 - Invalid materialization macro 'incremental_snapshot_merge' does not exist

with policy_terms as (
    select
        policy_id,
        effective_date,
        expiration_date,
        policyholder_id
    from {{ ref('dim_policy') }}
),

renewals as (
    select
        {{ dbt_utils.generate_surrogate_key(['p1.policy_id', 'p1.effective_date']) }} as renewal_id,
        p1.policy_id,
        p1.policyholder_id,
        p1.expiration_date as original_expiration,
        p2.effective_date as renewal_date,
        datediff('day', p1.expiration_date, p2.effective_date) as days_gap,
        case 
            when p2.policy_id is not null then true 
            else false 
        end as was_renewed
    from policy_terms p1
    left join policy_terms p2 
        on p1.policyholder_id = p2.policyholder_id
        and p2.effective_date between p1.expiration_date and dateadd('day', 30, p1.expiration_date)
        and p1.policy_id != p2.policy_id
)

select * from renewals
