with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    'PROD-' || lpad(row_num::varchar, 7, '0') as product_key,
    case mod(row_num, 8)
        when 0 then 'Basic Auto Coverage'
        when 1 then 'Premium Auto Coverage'
        when 2 then 'Comprehensive Plus'
        when 3 then 'Liability Only'
        when 4 then 'Full Coverage'
        when 5 then 'Collision Coverage'
        when 6 then 'Uninsured Motorist'
        else 'Gap Insurance'
    end || ' - ' || row_num::varchar as name,
    case mod(row_num, 5)
        when 0 then 'Liability'
        when 1 then 'Comprehensive'
        when 2 then 'Collision'
        when 3 then 'Uninsured Motorist'
        else 'Gap'
    end as coverage_type
from row_generator
