{{ config(materialized='table') }}

SELECT
    date,
    channelGrouping,
    SUM(newVisits) AS new_visits,
    SUM(visits) AS visits
FROM
    {{ source('raw','ga_data_raw') }}
GROUP BY
    date,
    channelGrouping