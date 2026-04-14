with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    'CLM-' || lpad(row_num::varchar, 7, '0') as claim_key,
    (mod(row_num, 1000000) + 1) as policy_key,
    dateadd(day, -mod(row_num * 3, 365), current_date())::date as report_date,
    dateadd(day, -mod(row_num * 3, 365) - mod(row_num, 7), current_date())::date as incident_date,

    -- Realistic claim status mix
    case
        when mod(abs(hash(row_num * 5)),  100) < 45 then 'closed'        -- 45%
        when mod(abs(hash(row_num * 5)),  100) < 65 then 'open'          -- 20%
        when mod(abs(hash(row_num * 5)),  100) < 80 then 'in_progress'   -- 15%
        when mod(abs(hash(row_num * 5)),  100) < 90 then 'cancelled'  -- 10%
        when mod(abs(hash(row_num * 5)),  100) < 95 then 'canceled'           --  6%
        when mod(abs(hash(row_num * 5)),  100) < 97 then 'new'     --  2%
        else                                              'under_review'    --  2%
    end as claim_status,

    -- Realistic claim cause distribution (collision most common)
    case
        when mod(abs(hash(row_num * 11)), 100) < 38 then 'Collision'    -- 38%
        when mod(abs(hash(row_num * 11)), 100) < 58 then 'Weather'      -- 20%
        when mod(abs(hash(row_num * 11)), 100) < 70 then 'Glass'        -- 12%
        when mod(abs(hash(row_num * 11)), 100) < 80 then 'Theft'        -- 10%
        when mod(abs(hash(row_num * 11)), 100) < 87 then 'Vandalism'    --  7%
        when mod(abs(hash(row_num * 11)), 100) < 93 then 'Mechanical'   --  6%
        when mod(abs(hash(row_num * 11)), 100) < 97 then 'Fire'         --  4%
        else                                              'Other'        --  3%
    end as claim_cause,

    -- Right-skewed loss amounts: most claims are small, few are large
    case
        when mod(abs(hash(row_num * 7)), 100) < 40 then
            -- 40% small claims: $500–$2,500
            500  + mod(abs(hash(row_num * 43)), 2000)
        when mod(abs(hash(row_num * 7)), 100) < 75 then
            -- 35% medium claims: $2,500–$10,000
            2500 + mod(abs(hash(row_num * 43)), 7500)
        when mod(abs(hash(row_num * 7)), 100) < 95 then
            -- 20% large claims: $10,000–$30,000
            10000 + mod(abs(hash(row_num * 43)), 20000)
        else
            -- 5% total-loss claims: $30,000–$75,000
            30000 + mod(abs(hash(row_num * 43)), 45000)
    end::decimal(18, 2) as loss_amount

from row_generator
