with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    row_num as policy_id,
    'POL-' || lpad(row_num::varchar, 10, '0') as policy_number,
    'PH-' || lpad((mod(row_num, 1000000) + 1)::varchar, 7, '0') as policyholder_key,
    'AGY-' || lpad((mod(row_num, 1000000) + 1)::varchar, 7, '0') as agency_key,
    'PROD-' || lpad((mod(row_num, 1000000) + 1)::varchar, 7, '0') as product_id,
    -- Generate VIN-like key matching vehicles
    upper(
        chr(65 + mod(mod(row_num, 1000000) + 1, 26)) ||
        chr(65 + mod((mod(row_num, 1000000) + 1) * 3, 26)) ||
        chr(65 + mod((mod(row_num, 1000000) + 1) * 7, 26)) ||
        lpad(mod(mod(row_num, 1000000) + 1, 100000000)::varchar, 8, '0') ||
        chr(65 + mod((mod(row_num, 1000000) + 1) * 11, 26)) ||
        lpad(mod((mod(row_num, 1000000) + 1) * 13, 100000)::varchar, 5, '0')
    ) as vehicle_key,
    dateadd(day, -mod(row_num * 7, 1825), current_date())::date as start_date,
    dateadd(day, -mod(row_num * 7, 1825) + 365, current_date())::date as end_date,
    case mod(row_num, 4)
        when 0 then 'active'
        when 1 then 'active'
        when 2 then 'expired'
        else 'cancelled'
    end as policy_status
from row_generator
