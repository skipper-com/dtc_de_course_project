{{ config(materialized='table') }}

WITH ga_raw_data AS(
    SELECT
        date,
        fullVisitorId,
        SUM (totals.transactions) AS total_transactions_per_user
    FROM
        {{ source('raw','ga_raw_data') }}
    WHERE
        totals.transactions IS NOT NULL
    GROUP BY
        date,
        fullVisitorId 
)

SELECT
    date,
    (SUM (total_transactions_per_user) / COUNT(fullVisitorId) ) AS avg_total_transactions_per_user
FROM
    ga_raw_data