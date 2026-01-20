with source as (
  select * from {{ source('raw_insurance', 'vehicles') }}
),
renamed as (
  select
    trim(vehicle_vin) as vehicle_vin,
    initcap(trim(make)) as make,
    initcap(trim(model)) as model,
    cast(year as integer) as year,
    initcap(trim(vehicle_type)) as vehicle_type
  from source
)
select * from renamed


