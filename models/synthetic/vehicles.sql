with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
),

makes as (
    select row_num,
        case mod(row_num, 15)
            when 0 then 'Toyota' when 1 then 'Honda' when 2 then 'Ford' when 3 then 'Chevrolet'
            when 4 then 'Nissan' when 5 then 'BMW' when 6 then 'Mercedes' when 7 then 'Audi'
            when 8 then 'Hyundai' when 9 then 'Kia' when 10 then 'Subaru' when 11 then 'Mazda'
            when 12 then 'Volkswagen' when 13 then 'Jeep' else 'Ram'
        end as make
    from row_generator
),

models as (
    select row_num,
        case mod(row_num, 15)
            when 0 then 'Camry' when 1 then 'Civic' when 2 then 'F-150' when 3 then 'Silverado'
            when 4 then 'Altima' when 5 then '3 Series' when 6 then 'C-Class' when 7 then 'A4'
            when 8 then 'Elantra' when 9 then 'Optima' when 10 then 'Outback' when 11 then 'CX-5'
            when 12 then 'Jetta' when 13 then 'Wrangler' else '1500'
        end as model
    from row_generator
)

select
    -- Generate VIN-like key (17 chars)
    upper(
        chr(65 + mod(rg.row_num, 26)) ||
        chr(65 + mod(rg.row_num * 3, 26)) ||
        chr(65 + mod(rg.row_num * 7, 26)) ||
        lpad(mod(rg.row_num, 100000000)::varchar, 8, '0') ||
        chr(65 + mod(rg.row_num * 11, 26)) ||
        lpad(mod(rg.row_num * 13, 100000)::varchar, 5, '0')
    ) as vehicle_vin,
    mk.make,
    md.model,
    2010 + mod(rg.row_num, 15) as year,
    case mod(rg.row_num, 5)
        when 0 then 'Sedan'
        when 1 then 'SUV'
        when 2 then 'Truck'
        when 3 then 'Coupe'
        else 'Hatchback'
    end as vehicle_type
from row_generator rg
join makes mk on rg.row_num = mk.row_num
join models md on rg.row_num = md.row_num
