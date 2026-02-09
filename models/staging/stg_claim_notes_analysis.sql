-- Analyzes claim adjuster notes using Snowflake Cortex LLM functions
-- This model extracts sentiment and key topics from free-text claim notes

with claim_notes as (
    select
        claim_key,
        adjuster_notes,
        created_at
    from {{ source('raw_insurance', 'claims') }}
    where adjuster_notes is not null
),

analyzed_notes as (
    select
        claim_key,
        adjuster_notes,
        created_at,
        -- Error: dbt0209 - No function SNOWFLAKE.CORTEX.COUNT_TOKENS
        -- This Cortex function does not exist
        SNOWFLAKE.CORTEX.COUNT_TOKENS(adjuster_notes, 'llama3-70b') as token_count,
        SNOWFLAKE.CORTEX.EXTRACT_SENTIMENT(adjuster_notes) as note_sentiment
    from claim_notes
)

select * from analyzed_notes
