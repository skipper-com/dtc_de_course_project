{{ config(materialized='table') }}

SELECT
    country,
    AVG(timeOnSite) AS avg_time_on_page
FROM
    {{ source('raw','ga_data_raw') }}
WHERE
    timeOnSite IS NOT NULL
GROUP BY
    country