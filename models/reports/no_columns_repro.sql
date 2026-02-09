-- depend_on: {{ ref('stg_products') }}

with source as (select * from stg_products)

 

select *

from source