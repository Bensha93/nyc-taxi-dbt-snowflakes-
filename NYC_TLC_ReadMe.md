
# NYC Taxi Analytics Pipeline — End-to-End Portfolio Project

> **From raw web data to a production-style analytics stack (Snowflake → dbt → Power BI) with geospatial enrichment via Wikidata.**  
> This README documents exactly what I did — scraping, loading, modeling, testing, documentation, and delivering an executive-ready Power BI report.

---

## 🎯 What I built
- **Scraped** NYC Taxi trip data (Yellow & Green) from the official NYC website using **Python**.
- **Ingested** raw files into **Snowflake** (a newly created `RAW` database).
- **Seeded** and **modeled** lookup data (zones, vendors, payment types, rate codes, trip types).
- **Set up dbt in VS Code**, connected to Snowflake, and implemented a **source → staging (ephemeral) → dim/fact** layered model.
- **Enriched** boroughs with **precise latitude/longitude** from **Wikidata (SPARQL)**.
- **Validated** the models with dbt tests and **documented** with YAML + dbt docs.
- **Exposed** the star schema to **Power BI** and delivered a clean, purpose-built report (visuals embedded below).

---

## 🧱 Tech Stack
**Python**, **Snowflake**, **dbt**, **Wikidata SPARQL**, **Power BI Desktop**

---

## 🗺️ Architecture (high level)
```
NYC Website ──> Python Scraper ──> RAW files ──> Snowflake (RAW schema)
                                        │
                                        └──> dbt (ephemeral staging) ──> dims + facts ──> dbt tests/docs
                                                                                 │
                                                                                 └──> Power BI (star schema + DAX)
```

---

## 📥 1) Scrape NYC Taxi data (Python)
- Parameterized **year/month** and **service** (`yellow`, `green`).
- Persisted **Parquet** for better types + faster ingestion.
- (Optional) Light normalization.

---

## ❄️ 2) Load to Snowflake (`RAW` database)
- Created a **warehouse**, **RAW** database, **RAW.TAXI** schema, **FILE FORMATs**, and an **internal STAGE**.
- **PUT** local Parquet files to stage; **COPY INTO** `RAW.TAXI.YELLOW_TRIP` and `RAW.TAXI.GREEN_TRIP`.
- Loaded lookup tables into `RAW` (zones, payment type, rate code, vendor, trip type).

---

## 🛠️ 3) dbt in VS Code (Snowflake target)
- Project structure with **ephemeral** `src_*` staging models, **dim** models, and **fact** models.
- Materializations: `staging/*` → **ephemeral**, `dim/*` → view/table, `fct/*` → table.
- `dbt seed`, `dbt run`, `dbt test`, `dbt docs generate`.

**Included model files (this repo):**
- Facts: `fct_yellow_cleansed.sql`, `fct_green_cleansed.sql`
- Dims: `dim_borough.sql`, `DIM_TAXI_ZONE_LOOKUP.sql`, `dim_payment_type.sql`, `dim_rate_code.sql`, `dim_vendor.sql`, `dim_trip_type.sql`
- Sources (ephemeral): `src_yellow_trip.sql`, `src_green_trip.sql`, `src_payment_type.sql`, `src_rate_code.sql`, `src_vendor.sql`, `src_trip_type.sql`
- Config: `dbt_project.yml`

---

## 🧭 4) Geospatial Enrichment (Wikidata SPARQL)
- Pulled **borough** coordinates via SPARQL and joined into `dim_borough` for accurate centroid mapping.
- Stored results in a lookup table and referenced in dim modeling.

---

## 🧩 5) Dimensional Model (Star)
- **Dimensions:** Borough (with lat/long), Zone, Vendor, Payment Type, Rate Code, Trip Type.
- **Facts:** `fct_yellow_cleansed`, `fct_green_cleansed` — standardized trip-level data with cleaned types and business rules.

---

## 🔎 6) Data Quality (dbt tests)
- **Schema tests:** `not_null`, `unique`, `accepted_values`.
- **Relationships** from facts → dims (FK coverage).
- **Logic checks:** non-negative fares/distances; valid time ordering; lat/long bounds.

---

## 📊 7) Power BI Report (embedded visuals)
Clean, navigable pages aimed at **executive** and **operations** users. Connected directly to Snowflake dims & facts.

### Executive Overview
![Executive Overview](sandbox:/mnt/data/p1.png)

### Geographic Insights
![Geographic Insights](sandbox:/mnt/data/p2.png)

### Fare & Revenue Analysis
![Fare & Revenue Analysis](sandbox:/mnt/data/p4.png)

### Passenger & Trip Behavior
![Passenger & Trip Behavior](sandbox:/mnt/data/p33.png)

### Operational Performance
![Operational Performance](sandbox:/mnt/data/p5.png)

---

## ✅ Fact Table Checks I ran
- **Row counts** vs. raw parity.
- **Monetary sanity** (fare, tip, total).
- **Key coverage** (no orphans on joins).
- **Temporal validity** (pickup < dropoff).
- **Geo integrity** (zone/borough match; coordinates present).

---

## 🚀 How to run
1. **Ingest (Python):** download monthly files to `data/ingest` as Parquet.
2. **Snowflake:** create `RAW` objects, stage files, and `COPY INTO` the raw tables.
3. **dbt:** configure Snowflake profile → `dbt seed` → `dbt run` → `dbt test` → `dbt docs generate`.
4. **Power BI:** connect to Snowflake; import `dim_*` and `fct_*`; build visuals (or reuse this layout).

---

## 📫 Contact
Happy to walk through trade-offs (incremental models, partitioning, cost control, geospatial options).

_— Your Name_
