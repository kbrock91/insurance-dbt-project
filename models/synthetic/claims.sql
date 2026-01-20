with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    'CLM-' || lpad(row_num::varchar, 7, '0') as claim_key,
    (mod(row_num, 1000000) + 1) as policy_key,
    dateadd(day, -mod(row_num * 3, 365), current_date())::date as report_date,
    dateadd(day, -mod(row_num * 3, 365) - mod(row_num, 7), current_date())::date as incident_date,
    case mod(row_num, 6)
        when 0 then 'open'
        when 1 then 'closed'
        when 2 then 'new'
        when 3 then 'under_review'
        when 4 then 'in_progress'
        else 'canceled'
    end as claim_status,
    case mod(row_num, 8)
        when 0 then 'Collision'
        when 1 then 'Theft'
        when 2 then 'Vandalism'
        when 3 then 'Weather'
        when 4 then 'Fire'
        when 5 then 'Mechanical'
        when 6 then 'Glass'
        else 'Other'
    end as claim_cause,
    (500 + mod(row_num * 23, 49500))::decimal(18,2) as loss_amount
from row_generator
