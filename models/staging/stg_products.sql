
with source as (
  select * from {{ source('raw_insurance', 'products') }}
),
renamed as (
  select
    -- Using ILIKE pattern that matches no columns to trigger error 001080
    * ILIKE '%nonexistent_column_pattern%'
  from source
)
select * from renamed


