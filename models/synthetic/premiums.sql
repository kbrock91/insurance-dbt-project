with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 1000000))
),

base_amounts as (
    select 
        row_num,
        500 + (mod(row_num * 17, 2000)) as gross_premium,
        25 + mod(row_num * 3, 75) as fees,
        mod(row_num * 7, 150) as discounts
    from row_generator
)

select
    rg.row_num as policy_key,
    dateadd(day, -mod(rg.row_num * 11, 730), current_date())::date as effective_date,
    ba.gross_premium::decimal(18,2) as gross_premium_amount,
    ba.fees::decimal(18,2) as fees,
    ba.discounts::decimal(18,2) as discounts,
    (ba.gross_premium + ba.fees - ba.discounts)::decimal(18,2) as net_premium_amount
from row_generator rg
join base_amounts ba on rg.row_num = ba.row_num
