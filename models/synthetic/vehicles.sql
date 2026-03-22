with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
),

-- Weighted make distribution (~US market share)
make_selection as (
    select
        row_num,
        case
            when mod(abs(hash(row_num)),       100) < 15 then 'Ford'         -- 15%
            when mod(abs(hash(row_num)),       100) < 29 then 'Toyota'       -- 14%
            when mod(abs(hash(row_num)),       100) < 41 then 'Chevrolet'    -- 12%
            when mod(abs(hash(row_num)),       100) < 53 then 'Honda'        -- 12%
            when mod(abs(hash(row_num)),       100) < 61 then 'Hyundai'      --  8%
            when mod(abs(hash(row_num)),       100) < 68 then 'Nissan'       --  7%
            when mod(abs(hash(row_num)),       100) < 73 then 'Jeep'         --  5%
            when mod(abs(hash(row_num)),       100) < 78 then 'Ram'          --  5%
            when mod(abs(hash(row_num)),       100) < 82 then 'Subaru'       --  4%
            when mod(abs(hash(row_num)),       100) < 86 then 'Kia'          --  4%
            when mod(abs(hash(row_num)),       100) < 89 then 'BMW'          --  3%
            when mod(abs(hash(row_num)),       100) < 92 then 'Mercedes'     --  3%
            when mod(abs(hash(row_num)),       100) < 95 then 'Mazda'        --  3%
            else                                              'Volkswagen'   --  5%
        end as make
    from row_generator
),

-- Model selected within each make using an independent hash
model_selection as (
    select
        row_num,
        make,
        case make
            when 'Ford' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'F-150'
                    when 1 then 'Explorer'
                    when 2 then 'Escape'
                    else        'Mustang'
                end
            when 'Toyota' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Camry'
                    when 1 then 'RAV4'
                    when 2 then 'Tacoma'
                    else        'Corolla'
                end
            when 'Chevrolet' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Silverado'
                    when 1 then 'Equinox'
                    when 2 then 'Malibu'
                    else        'Colorado'
                end
            when 'Honda' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Civic'
                    when 1 then 'CR-V'
                    when 2 then 'Accord'
                    else        'Pilot'
                end
            when 'Hyundai' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Elantra'
                    when 1 then 'Tucson'
                    when 2 then 'Santa Fe'
                    else        'Sonata'
                end
            when 'Nissan' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Altima'
                    when 1 then 'Rogue'
                    when 2 then 'Frontier'
                    else        'Sentra'
                end
            when 'Jeep' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Wrangler'
                    when 1 then 'Cherokee'
                    when 2 then 'Grand Cherokee'
                    else        'Gladiator'
                end
            when 'Ram' then
                case mod(abs(hash(row_num * 31)), 2)
                    when 0 then '1500'
                    else        '2500'
                end
            when 'Subaru' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Outback'
                    when 1 then 'Forester'
                    when 2 then 'Crosstrek'
                    else        'Impreza'
                end
            when 'Kia' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Sportage'
                    when 1 then 'Telluride'
                    when 2 then 'Sorento'
                    else        'K5'
                end
            when 'BMW' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then '3 Series'
                    when 1 then 'X5'
                    when 2 then '5 Series'
                    else        'X3'
                end
            when 'Mercedes' then
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'C-Class'
                    when 1 then 'E-Class'
                    when 2 then 'GLE'
                    else        'GLC'
                end
            when 'Mazda' then
                case mod(abs(hash(row_num * 31)), 3)
                    when 0 then 'CX-5'
                    when 1 then 'Mazda3'
                    else        'CX-9'
                end
            else -- Volkswagen
                case mod(abs(hash(row_num * 31)), 4)
                    when 0 then 'Jetta'
                    when 1 then 'Tiguan'
                    when 2 then 'Atlas'
                    else        'Golf'
                end
        end as model
    from make_selection
)

select
    upper(
        chr(65 + mod(rg.row_num, 26)) ||
        chr(65 + mod(rg.row_num * 3, 26)) ||
        chr(65 + mod(rg.row_num * 7, 26)) ||
        lpad(mod(rg.row_num, 100000000)::varchar, 8, '0') ||
        chr(65 + mod(rg.row_num * 11, 26)) ||
        lpad(mod(rg.row_num * 13, 100000)::varchar, 5, '0')
    ) as vehicle_vin,
    ms.make,
    ms.model,
    -- vehicle_type derived from model so make → model → type is always consistent
    case ms.model
        -- Trucks
        when 'F-150'         then 'Truck'
        when 'Silverado'     then 'Truck'
        when 'Colorado'      then 'Truck'
        when 'Tacoma'        then 'Truck'
        when 'Frontier'      then 'Truck'
        when '1500'          then 'Truck'
        when '2500'          then 'Truck'
        when 'Gladiator'     then 'Truck'
        -- SUVs
        when 'Explorer'      then 'SUV'
        when 'Escape'        then 'SUV'
        when 'RAV4'          then 'SUV'
        when 'Equinox'       then 'SUV'
        when 'CR-V'          then 'SUV'
        when 'Pilot'         then 'SUV'
        when 'Tucson'        then 'SUV'
        when 'Santa Fe'      then 'SUV'
        when 'Rogue'         then 'SUV'
        when 'Wrangler'      then 'SUV'
        when 'Cherokee'      then 'SUV'
        when 'Grand Cherokee' then 'SUV'
        when 'Outback'       then 'SUV'
        when 'Forester'      then 'SUV'
        when 'Crosstrek'     then 'SUV'
        when 'Sportage'      then 'SUV'
        when 'Telluride'     then 'SUV'
        when 'Sorento'       then 'SUV'
        when 'X5'            then 'SUV'
        when 'X3'            then 'SUV'
        when 'GLE'           then 'SUV'
        when 'GLC'           then 'SUV'
        when 'CX-5'          then 'SUV'
        when 'CX-9'          then 'SUV'
        when 'Tiguan'        then 'SUV'
        when 'Atlas'         then 'SUV'
        -- Coupes
        when 'Mustang'       then 'Coupe'
        -- Hatchbacks
        when 'Golf'          then 'Hatchback'
        when 'Impreza'       then 'Hatchback'
        -- Sedans (Camry, Corolla, Malibu, Civic, Accord, Elantra, Sonata,
        --         Altima, Sentra, K5, 3 Series, 5 Series, C-Class, E-Class,
        --         Mazda3, Jetta)
        else 'Sedan'
    end as vehicle_type,
    2010 + mod(abs(hash(rg.row_num * 17)), 15) as year
from row_generator rg
join model_selection ms on rg.row_num = ms.row_num
