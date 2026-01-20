with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
),

first_names as (
    select row_num, 
        case mod(row_num, 20)
            when 0 then 'James' when 1 then 'Mary' when 2 then 'John' when 3 then 'Patricia'
            when 4 then 'Robert' when 5 then 'Jennifer' when 6 then 'Michael' when 7 then 'Linda'
            when 8 then 'William' when 9 then 'Elizabeth' when 10 then 'David' when 11 then 'Barbara'
            when 12 then 'Richard' when 13 then 'Susan' when 14 then 'Joseph' when 15 then 'Jessica'
            when 16 then 'Thomas' when 17 then 'Sarah' when 18 then 'Charles' else 'Karen'
        end as first_name
    from row_generator
),

last_names as (
    select row_num,
        case mod(row_num, 20)
            when 0 then 'Smith' when 1 then 'Johnson' when 2 then 'Williams' when 3 then 'Brown'
            when 4 then 'Jones' when 5 then 'Garcia' when 6 then 'Miller' when 7 then 'Davis'
            when 8 then 'Rodriguez' when 9 then 'Martinez' when 10 then 'Hernandez' when 11 then 'Lopez'
            when 12 then 'Gonzalez' when 13 then 'Wilson' when 14 then 'Anderson' when 15 then 'Thomas'
            when 16 then 'Taylor' when 17 then 'Moore' when 18 then 'Jackson' else 'Martin'
        end as last_name
    from row_generator
),

states as (
    select row_num,
        case mod(row_num, 10)
            when 0 then 'CA' when 1 then 'TX' when 2 then 'FL' when 3 then 'NY'
            when 4 then 'IL' when 5 then 'PA' when 6 then 'OH' when 7 then 'GA'
            when 8 then 'NC' else 'MI'
        end as state
    from row_generator
)

select
    'PH-' || lpad(rg.row_num::varchar, 7, '0') as policyholder_key,
    fn.first_name,
    ln.last_name,
    dateadd(day, -mod(rg.row_num * 17, 25550), '2005-01-01')::date as date_of_birth,
    case mod(rg.row_num, 2) when 0 then 'M' else 'F' end as gender,
    lower(fn.first_name) || '.' || lower(ln.last_name) || rg.row_num::varchar || '@email.com' as email,
    '(' || lpad((200 + mod(rg.row_num, 800))::varchar, 3, '0') || ') ' ||
        lpad((100 + mod(rg.row_num * 11, 900))::varchar, 3, '0') || '-' ||
        lpad((1000 + mod(rg.row_num * 17, 9000))::varchar, 4, '0') as phone,
    (100 + mod(rg.row_num, 9900))::varchar || ' Main St' as address,
    case mod(rg.row_num, 10)
        when 0 then 'Los Angeles' when 1 then 'Houston' when 2 then 'Miami' when 3 then 'New York'
        when 4 then 'Chicago' when 5 then 'Philadelphia' when 6 then 'Columbus' when 7 then 'Atlanta'
        when 8 then 'Charlotte' else 'Detroit'
    end as city,
    st.state,
    lpad((10000 + mod(rg.row_num, 89999))::varchar, 5, '0') as zip
from row_generator rg
join first_names fn on rg.row_num = fn.row_num
join last_names ln on rg.row_num = ln.row_num
join states st on rg.row_num = st.row_num
