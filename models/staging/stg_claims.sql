with source as (
  select * from {{ ref('claims') }}
),
typed as (
  select
    cast(claim_key as varchar) as claim_id,
    cast(policy_key as varchar) as policy_id,
    cast(report_date as date) as report_date,
    cast(incident_date as date) as incident_date,
    -- normalize multi-word statuses to snake_case
    regexp_replace(lower(trim(claim_status)), '[\\s-]+', '_') as claim_status,
    initcap(trim(claim_cause)) as claim_cause,
    cast(loss_amount as decimal(18,2)) as loss_amount,
    case
      when regexp_replace(lower(trim(claim_status)), '[\\s-]+', '_') in ('closed','canceled') then false
      else true
    end as is_open
  from source
)
select * from typed
