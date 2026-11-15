-- NYC taxi data exploration

CREATE OR REPLACE TABLE taxi_data AS
SELECT * FROM read_csv('yellow_tripdata_2016-01.csv');

-- clean data 
CREATE OR REPLACE TABLE taxi_data_clean AS
SELECT
    tpep_pickup_datetime                    AS pickup_time,
    tpep_dropoff_datetime                   AS dropoff_time,
    passenger_count,
    trip_distance,
    RateCodeID                              AS rate_code,     -- 1 standard, 2 JFK, 3 Newark
    payment_type,                                             -- 1 card, 2 cash, 3 no charge, 4 dispute
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    date_diff('second', tpep_pickup_datetime, tpep_dropoff_datetime) / 60.0
                                            AS duration_min
FROM taxi_data
WHERE fare_amount > 0
  AND trip_distance > 0
  AND trip_distance < 100
  AND passenger_count BETWEEN 1 AND 6 -- max 6 passengers in NYC 
  AND date_diff('second', tpep_pickup_datetime, tpep_dropoff_datetime)
      BETWEEN 60 AND 10800;          -- 1 minute to 3 hours

-- daily trend of trips and revenue
CREATE OR REPLACE VIEW v_daily_trend AS
SELECT
    pickup_time::DATE               AS trip_date,
    COUNT(*)                        AS trips,
    ROUND(SUM(total_amount), 0)     AS revenue
FROM taxi_data_clean
GROUP BY ALL
ORDER BY trip_date;

SELECT * FROM v_daily_trend;

-- explore different trip types 
CREATE OR REPLACE VIEW v_airport_trips AS
SELECT
    CASE rate_code
        WHEN 1 THEN 'Standard'
        WHEN 2 THEN 'JFK (flat fare)'
        WHEN 3 THEN 'Newark'
        ELSE 'Other'
    END                             AS trip_type,
    COUNT(*)                        AS trips,
    ROUND(AVG(total_amount), 2)     AS avg_total,
    ROUND(AVG(trip_distance), 1)    AS avg_miles,
    ROUND(AVG(duration_min), 1)     AS avg_minutes,
    ROUND(SUM(total_amount), 0)     AS revenue
FROM taxi_data_clean
GROUP BY ALL
ORDER BY trips DESC;

SELECT * FROM v_airport_trips;

-- explore different payment types
CREATE OR REPLACE VIEW v_payment_mix AS
SELECT
    CASE payment_type
        WHEN 1 THEN 'Credit card'  WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'    WHEN 4 THEN 'Dispute'
        ELSE 'Other/Unknown'
    END                                                   AS payment_method,
    COUNT(*)                                              AS trips,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_trips,
    ROUND(AVG(total_amount), 2)                           AS avg_total
FROM taxi_data_clean
GROUP BY ALL
ORDER BY trips DESC;

SELECT * FROM v_payment_mix;

-- tips per hour for card trips
CREATE OR REPLACE VIEW v_tips_by_hour AS
SELECT
    hour(pickup_time)                                      AS pickup_hour,
    COUNT(*)                                               AS card_trips,
    ROUND(AVG(tip_amount), 2)                              AS avg_tip,
    ROUND(100.0 * SUM(tip_amount) / SUM(fare_amount), 1)   AS tip_pct_of_fare
FROM taxi_data_clean
WHERE payment_type = 1
GROUP BY ALL
ORDER BY pickup_hour;

SELECT * FROM v_tips_by_hour;

-- export summary tables to power BI
COPY (SELECT * FROM v_airport_trips) TO 'airport_trips.csv' (HEADER);
COPY (SELECT * FROM v_daily_trend)   TO 'daily_trend.csv'   (HEADER);
COPY (SELECT * FROM v_payment_mix)   TO 'payment_mix.csv'   (HEADER);
COPY (SELECT * FROM v_tips_by_hour)  TO 'tips_by_hour.csv'  (HEADER);
