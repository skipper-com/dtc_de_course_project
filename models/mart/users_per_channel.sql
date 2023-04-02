{{ config(materialized='table') }}

WITH ratio AS(
    SELECT
        date,
        channelGrouping,
        SUM(totals.newVisits) AS new_visits,
        SUM(totals.visits) AS visits
    FROM
        {{ source('raw','ga_raw_data') }}
    GROUP BY
        date,
        channelGrouping
)

SELECT
    date,
    channelGrouping,
    ( new_visits / visits ) AS new_existing_ration
FROM
    ratio
