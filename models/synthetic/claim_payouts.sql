with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    'CLM-' || lpad((mod(row_num, 1000000) + 1)::varchar, 7, '0') as claim_key,
    'PAY-' || lpad(row_num::varchar, 7, '0') as payout_key,
    dateadd(day, -mod(row_num * 5, 180), current_date())::date as payout_date,
    (100 + mod(row_num * 17, 24900))::decimal(18,2) as payout_amount,
    case mod(row_num, 4)
        when 0 then 'Repair'
        when 1 then 'Rental'
        when 2 then 'Settlement'
        else 'Medical'
    end as payout_type
from row_generator
