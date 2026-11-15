# NYC Yellow Taxi Trip Analysis (January 2016)

An analysis of about 11 million NYC yellow taxi trips from January 2016, using **DuckDB (SQL)** for cleaning and analysis and **Power BI** for the dashboard.

The goal is to answer simple business questions a taxi operator or city transport analyst would care about: when demand peaks, how riders pay, how tipping changes through the day, and how airport trips compare with regular city trips.

![Dashboard](dashboard/dashboard.png)

---

## Business Questions

1. How do trip volume and revenue change day to day across the month?
2. How do airport trips (JFK, Newark) compare with standard trips on fare, distance and duration?
3. What share of trips are paid by card vs. cash?
4. How does tipping change by hour of the day?

---

## Tools

| Tool | Used for |
|---|---|
| DuckDB | Loading the raw CSV, cleaning, analysis queries |
| SQL | All transformations and aggregations |
| Power BI | Interactive dashboard |
| GitHub | Version control and portfolio |

---

## Dataset

- **Source:** [NYC Yellow Taxi Trip Data on Kaggle](https://www.kaggle.com/datasets/elemento/nyc-yellow-taxi-trip-data), originally published by the NYC Taxi & Limousine Commission (TLC)
- **File used:** `yellow_tripdata_2016-01.csv` (about 1.7 GB, one row per trip)
- **Key fields:** pickup and dropoff timestamps, passenger count, trip distance, rate code, payment type, fare, tip, tolls, total amount

The raw data is not included in this repo because of its size. Download it from the Kaggle link above.

---

## Project Structure

```
nyc-taxi-analysis/
├── README.md
├── sql/
│   └── nyc_taxi_queries.sql   # every query used in this project
├── exports/                   # summary CSVs fed into Power BI
│   ├── daily_trend.csv
│   ├── airport_trips.csv
│   ├── payment_mix.csv
│   └── tips_by_hour.csv
└── dashboard/
    ├── nyc_taxi_dashboard.pbix
    └── dashboard.png
```

---

## Process

### 1. Load the raw data

```sql
CREATE OR REPLACE TABLE taxi_data AS
SELECT * FROM read_csv('yellow_tripdata_2016-01.csv');
```

### 2. Clean the data

The raw data contains records that can't be real trips: zero or negative fares, 0-mile trips, trips with 0 passengers, and trips where the dropoff time comes before the pickup time. These would distort averages, so the cleaning step keeps only trips that:

- have a fare above $0
- are more than 0 and less than 100 miles long
- carry 1 to 6 passengers
- last between 1 minute and 3 hours

It also renames columns for readability and adds a `duration_min` column calculated from the pickup and dropoff times.

```sql
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
  AND passenger_count BETWEEN 1 AND 6
  AND date_diff('second', tpep_pickup_datetime, tpep_dropoff_datetime)
      BETWEEN 60 AND 10800;          -- 1 minute to 3 hours
```

### 3. Analysis

Each analysis is saved as a view so it can be rerun or exported in one line.

#### Daily trend: trips and revenue per day

```sql
CREATE OR REPLACE VIEW v_daily_trend AS
SELECT
    pickup_time::DATE               AS trip_date,
    COUNT(*)                        AS trips,
    ROUND(SUM(total_amount), 0)     AS revenue
FROM taxi_data_clean
GROUP BY ALL
ORDER BY trip_date;

SELECT * FROM v_daily_trend;
```

#### Airport trips vs. standard trips

```sql
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
```

#### Payment mix: card vs. cash

```sql
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
```

#### Tipping by hour (card trips only)

```sql
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
```

### 4. Export for Power BI

Rather than loading 11 million rows into Power BI, the summary views are exported as small CSVs and the dashboard is built from those.

```sql
COPY (SELECT * FROM v_airport_trips) TO 'airport_trips.csv' (HEADER);
COPY (SELECT * FROM v_daily_trend)   TO 'daily_trend.csv'   (HEADER);
COPY (SELECT * FROM v_payment_mix)   TO 'payment_mix.csv'   (HEADER);
COPY (SELECT * FROM v_tips_by_hour)  TO 'tips_by_hour.csv'  (HEADER);
```

---

## Key Findings

> Replace the bracketed values with the numbers from your query results.

- **Data quality:** cleaning removed **[X]%** of raw records (invalid fares, zero-distance trips, impossible durations).
- **Daily demand:** trips ranged from **[X]** to **[Y]** per day. **[Describe any notable dip or spike, e.g. a storm or holiday, and what it did to revenue.]**
- **Airport trips:** JFK trips made up only **[X]%** of trips but **[Y]%** of revenue, with an average total of **$[X]** vs. **$[Y]** for standard trips.
- **Payments:** **[X]%** of trips were paid by card and **[Y]%** in cash.
- **Tipping:** card riders tipped an average of **[X]%** of the fare, highest around **[hour]** and lowest around **[hour]**.

## Recommendations

> Turn each finding into an action. For example:

- **[e.g. Position more drivers near airports during peak arrival hours, since airport trips earn far more per ride.]**
- **[e.g. Encourage card payments, since card trips record tips and have a higher average total.]**

---

## Limitations

- **Cash tips are not recorded** in TLC data, so tip analysis covers card payments only.
- The analysis covers **one month** (January 2016), so it doesn't show seasonal patterns.
- Cleaning thresholds (e.g. a 100-mile cap and a 3-hour cap) are judgment calls. They remove obvious errors but may also drop a small number of genuine unusual trips.
