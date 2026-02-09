{{
    config(
        materialized='table'
    )
}}

-- MetricFlow time spine model
-- Required for semantic layer time-based aggregations

{{ generate_date_spine('2020-01-01', '2030-12-31') }}
