## Insurance Workshop Guide (Snowflake + dbt)

This workshop builds on your current car insurance dbt project, using Snowflake and seeds. Follow these steps to explore the models, add tests, and practice safe changes.

### 1) Get familiar with the project & create a feature branch
- Open the project and skim `models/` (staging, marts, reports).
- Create a feature branch for your work (e.g., `workshop_YYYYMMDD_firstinitiallastname`). Keep all changes on your branch; we’ll build from it later.

Key models to know:
- Staging: `stg_policyholders`, `stg_agencies`, `stg_products`, `stg_vehicles`, `stg_policies`, `stg_claims`, `stg_claim_payouts`
- Marts: `dim_policyholder`, `dim_agency`, `dim_product`, `dim_vehicle`, `dim_policy`, `dim_date`, `fct_claims`, `fct_premiums`
- Reports: examples under `models/reports/`

Run build:
```bash
dbt seed --full-refresh
dbt build
```

### 2) Data quality – generic tests with Copilot
- Open a staging model like `models/staging/stg_policyholders.sql` (also try `stg_agencies.sql`, `stg_claims.sql`).
- Use Copilot → Documentation to generate a YAML with model/column descriptions; edit for clarity and save next to the model.
- Use Copilot → Generic Tests to add tests (e.g., `unique`, `not_null`) to primary keys and important columns. Save the YAML.
- Run:
```bash
dbt build
```
Tests run in dependency order; failures halt downstream builds.

### 3) Data quality – custom SQL data tests
Create a custom SQL test for a business rule.
- Create (or open) the `tests/` directory.
- New file: `tests/test_fct_claims_outstanding_nonnegative.sql` with:
```sql
select *
from {{ ref('fct_claims') }}
where outstanding_amount < 0
```
If the query returns rows, the test fails. Save and run:
```bash
dbt build
```

### 4) Data quality – leverage packages (dbt-expectations)
Add reusable package tests.
- At repo root, create `packages.yml`:
```yaml
packages:
  - package: calogica/dbt_expectations
    version: 0.10.6
```
- Install:
```bash
dbt deps
```
- In your marts YAML (e.g., near `fct_premiums`), add a package test:
```yaml
models:
  - name: fct_premiums
    columns:
      - name: net_premium_amount
        description: Net premium after fees and discounts
        data_tests:
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
```
- Run:
```bash
dbt build
```

### 5) Data quality – handling failures (simulate a bad record)
Demonstrate that failing tests protect downstream models.
- Open `models/staging/stg_policyholders.sql`.
- Temporarily append a deliberately bad row to the final select:
```sql
union all
select
  null as policyholder_id,
  'Bad' as first_name,
  'Record' as last_name,
  cast(null as date) as date_of_birth,
  'X' as gender,
  'bad@example.com' as email,
  '(000) 000-0000' as phone,
  'Unknown' as address,
  'Nowhere' as city,
  'NA' as state,
  '00000' as zip
```
- Ensure you have a `not_null` test on `policyholder_id` (Step 2). Run:
```bash
dbt build
```
Observe that dbt halts when the test fails, preventing downstream models from building. Remove the `union all` block and re-run for a clean build.

### 6) Native dbt unit tests (v1.8+) – phone normalization
This project includes a native unit test verifying `stg_policyholders` normalizes phone into `(XXX) XXX-XXXX`.
- See `models/staging/stg_policyholders_unit_tests.yml`.
- Run:
```bash
dbt test --select stg_policyholders_phone_format
```

### 7) Mark a model as public (dbt Mesh)
Make a model reusable across projects.
- Open `models/marts/fct_claims.sql` and add at the top:
```sql
{{
  config(
    access='public'
  )
}}
```
- Commit the change on your feature branch (e.g., "workshop: add tests, mark fct_claims public").
- Run:
```bash
dbt build
```

### Reference queries
- Highest premiums by state: join `fct_premiums` → `dim_policy` → `dim_policyholder` and group by `state`.
- Most frequent claims by product: join `fct_claims` → `dim_policy` → `dim_product` and count claims.

### Notes
- Warehouse: Snowflake (configure via your dbt profile).
- Seeds are defined under `seeds/` with per-file types in `dbt_project.yml`.
- Staging standardizes raw column inconsistencies (e.g., `_key` → `_id`, `name` → `<entity>_name`).

