{{
    config(
        materialized='incremental',
        unique_key='claim_id'
    )
}}

with claims as (
  select * from {{ ref('stg_claims') }}
),
payouts as (
  select claim_id, sum(payout_amount) as total_payout_amount
  from {{ ref('stg_claim_payouts') }}
  group by 1
),
joined as (
  select
    c.claim_id,
    c.policy_id,
    c.report_date,
    c.incident_date,
    c.claim_status,
    c.claim_cause,
    coalesce(c.loss_amount, 0) as loss_amount,
    coalesce(p.total_payout_amount, 0) as total_payout_amount,
     coalesce(c.loss_amount, 0) - coalesce(p.total_payout_amount, 0) as outstanding_amount
  from claims c
  left join payouts p on c.claim_id = p.claim_id
)
select * from joined
{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where report_date > (select max(report_date) from {{ this }}) 
{% endif %}

