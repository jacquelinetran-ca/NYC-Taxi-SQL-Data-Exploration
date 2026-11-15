# NYC Yellow Taxi Trip Analysis (January 2016)

An analysis of about 11 million NYC yellow taxi trips from January 2016, using **DuckDB (SQL)** for cleaning and analysis and **Power BI** for the dashboard.

The goal is to answer simple business questions a taxi operator or city transport analyst would care about: when demand peaks, how riders pay, how tipping changes through the day, and how airport trips compare with regular city trips.

## Business Questions

1. How do trip volume and revenue change day to day across the month?
2. How do airport trips (JFK, Newark) compare with standard trips on fare, distance and duration?
3. What share of trips are paid by card vs. cash?
4. How does tipping change by hour of the day?

## Tools

| Tool | Used for |
|---|---|
| DuckDB | Loading the raw CSV, cleaning, analysis queries |
| SQL | All transformations and aggregations |
| Power BI | Interactive dashboard |
| GitHub | Version control and portfolio |

## Dataset

- **Source:** [NYC Yellow Taxi Trip Data on Kaggle](https://www.kaggle.com/datasets/elemento/nyc-yellow-taxi-trip-data), originally published by the NYC Taxi & Limousine Commission (TLC)
- **File used:** `yellow_tripdata_2016-01.csv` (about 1.7 GB, one row per trip)
- **Key fields:** pickup and dropoff timestamps, passenger count, trip distance, rate code, payment type, fare, tip, tolls, total amount

The raw data is not included in this repo because of its size. Download it from the Kaggle link above.


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
## Key Findings

- **Data quality:** cleaning removed **200k** of raw records (invalid fares, zero-distance trips, impossible durations).
- **Daily demand:** trips ranged from **76904** to **430649** per day.

  <img width="104" height="124" alt="image" src="https://github.com/user-attachments/assets/e4b6a2c3-8f15-4891-a667-a8c25528dae2" />

- **Airport trips:** JFK trips made up only **1.98%** of trips but **8.21%** of revenue, with an average total of **$[64.59]** vs. **$[14.36]** for standard trips.
- **Payments:** **[66.2]%** of trips were paid by card and **33.5%** in cash.
- **Tipping:** card riders tipped an average of **20%** of the fare, highest around **4pm** and lowest around **[3am]**.

## Limitations

- **Cash tips are not recorded** in TLC data, so tip analysis covers card payments only.
- The analysis covers **one month** (January 2016), so it doesn't show seasonal patterns.
- Cleaning thresholds (e.g. a 100-mile cap and a 3-hour cap) are judgment calls. They remove obvious errors but may also drop a small number of genuine unusual trips.
