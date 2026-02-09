with source as (
  select * from {{ source('raw_insurance', 'products') }}
),
renamed as (
  select
    cast(product_key as varchar) as product_id,
    trim(name) as product_name,
    trim(coverage_type) as coverage_type
  from source
)
select * from renamed


