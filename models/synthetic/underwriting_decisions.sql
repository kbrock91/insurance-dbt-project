with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 50000))
)

select
    row_num as decision_id,
    'APP-' || lpad(row_num::varchar, 6, '0') as application_id,
    case 
        when mod(row_num, 10) < 8 then row_num  -- 80% approved have policy_id
        else null  -- declined/referred have no policy_id
    end as policy_id,
    'UW-' || lpad((mod(row_num, 50) + 1)::varchar, 3, '0') as underwriter_id,
    dateadd(day, -mod(row_num * 7, 730), current_date())::date as decision_date,
    case mod(row_num, 10)
        when 0 then 'DECLINED'
        when 1 then 'DECLINED'
        when 2 then 'REFERRED'
        else 'APPROVED'
    end as decision_outcome,
    (40 + mod(row_num * 17, 55))::int as risk_score,
    case mod(row_num, 10)
        when 0 then null  -- declined
        when 1 then null  -- declined
        when 2 then null  -- referred
        when 3 then -10.00
        when 4 then -5.00
        when 5 then 0.00
        when 6 then 0.00
        when 7 then 5.00
        when 8 then 10.00
        else 15.00
    end::decimal(5,2) as premium_adjustment_pct,
    case mod(row_num, 10)
        when 0 then case mod(row_num, 4)
            when 0 then 'High risk area'
            when 1 then 'Prior claims history'
            when 2 then 'Credit score below threshold'
            else 'Vehicle age exceeds limit'
        end
        when 1 then case mod(row_num, 3)
            when 0 then 'Multiple violations'
            when 1 then 'Fraud indicators'
            else 'Coverage not available'
        end
        else null
    end as decline_reason,
    case mod(row_num, 8)
        when 0 then 'Standard risk profile - auto approved'
        when 1 then 'Low risk applicant with clean history'
        when 2 then 'Minor risk factors identified'
        when 3 then 'Requires additional documentation'
        when 4 then 'Premium adjustment applied per guidelines'
        when 5 then 'Borderline case - manager approved'
        when 6 then 'Excellent driving record'
        else 'Reviewed and approved per underwriting standards'
    end as notes
from row_generator
