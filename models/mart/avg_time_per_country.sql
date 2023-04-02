{{ config(materialized='table') }}

SELECT
    date,
    country,
    SUM (timeOnSite) AS total_time_on_page
FROM
    {{ source('raw','ga_data_raw') }}
WHERE
    timeOnSite IS NOT NULL
GROUP BY
    date,
    country