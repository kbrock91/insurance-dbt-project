with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    'AGY-' || lpad(row_num::varchar, 7, '0') as agency_key,
    'Agency ' || row_num::varchar as name,
    case mod(row_num, 5)
        when 0 then 'Northeast'
        when 1 then 'Southeast'
        when 2 then 'Midwest'
        when 3 then 'Southwest'
        else 'West'
    end as region,
    'agency' || row_num::varchar || '@insurance.com' as email,
    '(' || lpad((200 + mod(row_num, 800))::varchar, 3, '0') || ') ' ||
        lpad((100 + mod(row_num * 7, 900))::varchar, 3, '0') || '-' ||
        lpad((1000 + mod(row_num * 13, 9000))::varchar, 4, '0') as phone,
    case mod(row_num, 3)
        when 0 then 'Direct'
        when 1 then 'Broker'
        else 'Agent'
    end as channel_type
from row_generator
