## Insurance dbt Project (Snowflake + Seeds)

This project models a small car insurance domain using dbt with seed CSVs as raw sources. It builds clean staging models and a simple star schema mart for analytics.

### Key Questions
- Where are premiums the highest?
- Which products have the most frequent claims?

### Technology
- Adapter: dbt-snowflake
- Warehouse: Snowflake (set via your dbt `profiles.yml` in `~/.dbt` or your chosen profiles dir)

### Quickstart
1) Install dbt-snowflake
```bash
python -m venv .venv && source .venv/bin/activate
pip install --upgrade pip
pip install dbt-snowflake==1.8.2
```

2) Configure your Snowflake profile (example):
```yaml
insurance_dbt:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <account>
      user: <user>
      password: <password>
      role: <role>
      database: <database>
      warehouse: <warehouse>
      schema: INSURANCE_DEV
      threads: 4
      client_session_keep_alive: false
```

3) Initialize and build
```bash
dbt debug
dbt seed --full-refresh
dbt build
```

This will load seeds to Snowflake and build all models.

### Project Structure
```
seeds/                      # raw CSVs loaded as seeds
models/
  staging/                  # cleaned/typed staging models (views)
  marts/                    # star schema (tables)
```

### Star Schema Overview
- Dimensions: `dim_agency`, `dim_policyholder`, `dim_product`, `dim_vehicle`, `dim_policy`, `dim_date`
- Facts: `fct_claims`, `fct_premiums`

### Example Analytical Queries

Highest net premiums by state (top 10):
```sql
select
  ph.state,
  sum(pr.net_premium_amount) as total_net_premium
from {{ ref('fct_premiums') }} pr
join {{ ref('dim_policy') }} p
  on p.policy_id = pr.policy_id
join {{ ref('dim_policyholder') }} ph
  on ph.policyholder_id = p.policyholder_id
group by 1
order by total_net_premium desc
limit 10;
```

Most frequent claims by product:
```sql
select
  prod.product_name,
  count(*) as claim_count
from {{ ref('fct_claims') }} c
join {{ ref('dim_policy') }} p
  on p.policy_id = c.policy_id
join {{ ref('dim_product') }} prod
  on prod.product_id = p.product_id
group by 1
order by claim_count desc;
```

Average payout per claim by claim cause:
```sql
select
  claim_cause,
  avg(total_payout_amount) as avg_payout
from {{ ref('fct_claims') }}
group by 1
order by avg_payout desc;
```

### Notes
- All IDs in this sample project are natural keys from the seeds; surrogate keys are omitted to keep the project lightweight.
- `dim_date` is generated using Snowflake's `generator` + `seq4()` for a modest date range.


