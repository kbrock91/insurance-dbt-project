with source as (
    select * from {{ source('raw_insurance', 'underwriting_decisions') }}
),

cleaned as (
    select
        decision_id,
        application_id,
        policy_id,
        underwriter_id,
        decision_date,
        decision_outcome,
        risk_score,
        premium_adjustment_pct,
        decline_reason,
        notes
    from source
)

select * from cleaned
