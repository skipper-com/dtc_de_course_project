{{ config(materialized='table') }}

SELECT
    date,
    device.browser,
    SUM ( totals.transactions ) AS total_transactions
FROM
    {{ source('raw','ga_raw_data') }}
GROUP BY
    date,
    device.browser
ORDER BY
    total_transactions DESC