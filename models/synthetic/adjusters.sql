with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 500))
)

select
    'ADJ-' || lpad(row_num::varchar, 5, '0') as adjuster_key,
    case mod(row_num, 20)
        when 0 then 'James'
        when 1 then 'Mary'
        when 2 then 'Robert'
        when 3 then 'Patricia'
        when 4 then 'John'
        when 5 then 'Jennifer'
        when 6 then 'Michael'
        when 7 then 'Linda'
        when 8 then 'David'
        when 9 then 'Elizabeth'
        when 10 then 'William'
        when 11 then 'Barbara'
        when 12 then 'Richard'
        when 13 then 'Susan'
        when 14 then 'Joseph'
        when 15 then 'Jessica'
        when 16 then 'Thomas'
        when 17 then 'Sarah'
        when 18 then 'Christopher'
        else 'Karen'
    end as first_name,
    case mod(row_num, 15)
        when 0 then 'Smith'
        when 1 then 'Johnson'
        when 2 then 'Williams'
        when 3 then 'Brown'
        when 4 then 'Jones'
        when 5 then 'Garcia'
        when 6 then 'Miller'
        when 7 then 'Davis'
        when 8 then 'Rodriguez'
        when 9 then 'Martinez'
        when 10 then 'Wilson'
        when 11 then 'Anderson'
        when 12 then 'Taylor'
        when 13 then 'Thomas'
        else 'Moore'
    end as last_name,
    'adjuster' || row_num::varchar || '@insurance.com' as email,
    '(' || lpad((200 + mod(row_num, 800))::varchar, 3, '0') || ') ' ||
        lpad((100 + mod(row_num * 7, 900))::varchar, 3, '0') || '-' ||
        lpad((1000 + mod(row_num * 13, 9000))::varchar, 4, '0') as phone,
    case mod(row_num, 4)
        when 0 then 'Auto'
        when 1 then 'Property'
        when 2 then 'Liability'
        else 'Multi-Line'
    end as specialty,
    case mod(row_num, 5)
        when 0 then 'Northeast'
        when 1 then 'Southeast'
        when 2 then 'Midwest'
        when 3 then 'Southwest'
        else 'West'
    end as region,
    case mod(row_num, 3)
        when 0 then 'Senior'
        when 1 then 'Staff'
        else 'Junior'
    end as level,
    dateadd(day, -mod(row_num * 17, 3650), current_date()) as hire_date,
    case 
        when mod(row_num, 20) = 0 then false
        else true
    end as is_active
from row_generator
