{{ config(materialized='table') }}

WITH ga_data AS(
    SELECT
        date,
        fullVisitorId,
        SUM (transactions) AS total_transactions_per_user
    FROM
        {{ source('raw','ga_data_raw') }}
    WHERE
        transactions IS NOT NULL
    GROUP BY
        date,
        fullVisitorId 
)

SELECT
    date,
    (SUM (total_transactions_per_user) / COUNT(fullVisitorId) ) AS avg_total_transactions_per_user
FROM
    ga_data
GROUP BY
    date