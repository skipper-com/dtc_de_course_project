{{ config(materialized='table') }}

SELECT
    date,
    browser,
    SUM (transactions) AS total_transactions
FROM
    {{ source('raw','ga_data_raw') }}
GROUP BY
    date,
    browser
ORDER BY
    total_transactions DESC