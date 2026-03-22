with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
)

select
    'CLM-' || lpad((mod(row_num, 1000000) + 1)::varchar, 7, '0') as claim_key,
    'PAY-' || lpad(row_num::varchar, 7, '0') as payout_key,
    dateadd(day, -mod(row_num * 5, 180), current_date())::date as payout_date,

    -- Payout type distribution: repairs are most common
    case
        when mod(abs(hash(row_num * 13)), 100) < 55 then 'Repair'       -- 55%
        when mod(abs(hash(row_num * 13)), 100) < 75 then 'Settlement'   -- 20%
        when mod(abs(hash(row_num * 13)), 100) < 90 then 'Rental'       -- 15%
        else                                              'Medical'      -- 10%
    end as payout_type,

    -- Right-skewed payout amounts, correlated to type bucket via same hash seed as claims
    case
        when mod(abs(hash(row_num * 7)), 100) < 40 then
            -- Small payouts: $300–$2,000
            300  + mod(abs(hash(row_num * 43)), 1700)
        when mod(abs(hash(row_num * 7)), 100) < 75 then
            -- Medium payouts: $2,000–$8,500
            2000 + mod(abs(hash(row_num * 43)), 6500)
        when mod(abs(hash(row_num * 7)), 100) < 95 then
            -- Large payouts: $8,500–$25,000
            8500 + mod(abs(hash(row_num * 43)), 16500)
        else
            -- Total-loss payouts: $25,000–$65,000
            25000 + mod(abs(hash(row_num * 43)), 40000)
    end::decimal(18, 2) as payout_amount

from row_generator
