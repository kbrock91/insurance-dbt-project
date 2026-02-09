with claim_notes as (
    select
        claim_id,
        adjuster_id,
        note_date,
        adjuster_notes,
        note_type
    from {{ source('raw_insurance', 'claim_notes') }}
    where adjuster_notes is not null
),

analyzed_notes as (
    select
        claim_id,
        adjuster_id,
        note_date,
        adjuster_notes,
        note_type,
        SNOWFLAKE.CORTEX.COUNT_TOKENS(adjuster_notes, 'llama3-70b') as token_count,
        SNOWFLAKE.CORTEX.SENTIMENT(adjuster_notes) as note_sentiment
    from claim_notes
)

select * from analyzed_notes
