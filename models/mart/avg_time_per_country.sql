{{ config(materialized='table') }}

SELECT
    date,
    geoNetwork.country,
    SUM (totals.timeOnSite) AS total_time_on_page
FROM
    {{ source('raw','ga_raw_data') }}
WHERE
    totals.timeOnSite IS NOT NULL
GROUP BY
    date,
    geoNetwork.country 


--**What is the average time purchasers spent on site per country?**
