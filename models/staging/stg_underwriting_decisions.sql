-- Staging model for underwriting decision records
-- Error: dbt0214 - Table 'ANALYTICS.DBT_KBROCK_INSURANCE.UNDERWRITING_DECISIONS' is missing in remote

with source as (
    -- This source table does not exist in the database
    select * from {{ source('raw_insurance', 'underwriting_decisions') }}
),

cleaned as (
    select
        decision_id,
        application_id,
        policy_id,
        underwriter_id,
        decision_date,
        decision_outcome,  -- APPROVED, DECLINED, REFERRED
        risk_score,
        premium_adjustment_pct,
        decline_reason,
        notes
    from source
)

select * from cleaned
