{{ config(materialized='table') }}

WITH ratio AS(
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
)

SELECT
    date,
    channelGrouping,
    (SUM(new_visits) / SUM(visits)) AS new_existing_ration
FROM
    ratio
GROUP BY
    date,
    channelGrouping
