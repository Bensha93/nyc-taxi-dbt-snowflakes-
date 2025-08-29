# NYC Taxi Analytics Pipeline — End‑to‑End Portfolio Project

> **From raw web data to a production‑style analytics stack (Snowflake → dbt → Power BI) with geospatial enrichment via Wikidata.**  
> This README walks through every step I executed: scraping, loading, modeling, testing, documentation, and visualization. It’s written to showcase practical data engineering skills to recruiters and hiring managers.

---

## 🎯 What I built

- **Scraped** NYC Taxi trip data (Yellow & Green) from the official NYC website using **Python**.
- **Ingested** raw CSV/Parquet files into **Snowflake** (a newly created `RAW` database).
- **Seeded** and **modeled** lookup data (zones, vendors, payment types, rate codes, trip types).
- **Set up dbt in VS Code**, connected to Snowflake, and implemented a **source → staging (ephemeral) → dim/fact** layered model.
- **Enriched** boroughs with **precise latitude/longitude** from **Wikidata** using **SPARQL**.
- **Validated** with dbt tests and **documented** the project (dbt docs).
- **Delivered** an interactive **Power BI** report with a clean, recruiter‑friendly design ready for exec‑level insights.

---

## 🧱 Tech Stack

- **Ingestion:** Python (requests, pandas/pyarrow), optional Snowflake Connector for Python or SnowSQL
- **Warehouse:** Snowflake (database: `RAW`, plus `ANALYTICS`/`TRANSFORM` schemas)
- **Transformation & Testing:** **dbt** (ephemeral staging, sources, seeds, dim/fact layers)
- **Metadata & Docs:** dbt docs + YAML
- **Geospatial Enrichment:** Wikidata **SPARQL**
- **BI:** **Power BI Desktop** (model + curated visuals)

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

## 📥 1) Scrape NYC Taxi data with Python

**Goal:** Automate download of Yellow & Green trip datasets and persist them locally/cloud, ready for Snowflake load.

Key ideas:
- Parameterize **year/month** and **service** (`yellow`, `green`).
- Write out as **Parquet** (preferred) or CSV.
- Optional: chunked processing to keep memory stable.

Example skeleton (abbrev.): 

```python
import os, io, requests, pandas as pd

BASE_URL = "https://.../nyc-tlc/trip-data/"  # replace with the official path
FILES = [
    # e.g., "yellow_tripdata_2023-01.parquet", "green_tripdata_2023-01.parquet"
]

OUTDIR = "data/ingest"
os.makedirs(OUTDIR, exist_ok=True)

for fname in FILES:
    url = f"{BASE_URL}{fname}"
    r = requests.get(url, timeout=60)
    r.raise_for_status()
    with open(os.path.join(OUTDIR, fname), "wb") as f:
        f.write(r.content)
    # Optional: read and light-clean
    if fname.endswith(".parquet"):
        df = pd.read_parquet(os.path.join(OUTDIR, fname))
    else:
        df = pd.read_csv(os.path.join(OUTDIR, fname))
    # Minimal normalization steps here if needed
```

> **Tip:** Prefer Parquet: smaller, typed, and Snowflake ingests faster with external stages.  

---

## ❄️ 2) Load to Snowflake (create `RAW` database)

Create a **database**, **warehouse**, **schema**, and **file format**. You can use **SnowSQL** or the **Python connector**.

```sql
-- 1) Core objects
CREATE WAREHOUSE IF NOT EXISTS WH_XS WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
CREATE DATABASE IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS RAW.TAXI;

-- 2) File formats
CREATE OR REPLACE FILE FORMAT RAW.TAXI.CSV_FMT TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '\"' SKIP_HEADER = 1;
CREATE OR REPLACE FILE FORMAT RAW.TAXI.PARQUET_FMT TYPE = 'PARQUET';

-- 3) Internal stage
CREATE OR REPLACE STAGE RAW.TAXI.INT_STAGE FILE_FORMAT = RAW.TAXI.PARQUET_FMT;
```

Upload files to the stage (via SnowSQL):
```bash
snowsql -q "PUT file://data/ingest/* @RAW.TAXI.INT_STAGE AUTO_COMPRESS=TRUE"
```

Create Raw Tables and Load:
```sql
CREATE OR REPLACE TABLE RAW.TAXI.YELLOW_TRIP ( ... ); -- columns aligned to source
CREATE OR REPLACE TABLE RAW.TAXI.GREEN_TRIP  ( ... );

COPY INTO RAW.TAXI.YELLOW_TRIP
  FROM @RAW.TAXI.INT_STAGE PATTERN='.*yellow.*parquet' FILE_FORMAT=(FORMAT_NAME=RAW.TAXI.PARQUET_FMT);

COPY INTO RAW.TAXI.GREEN_TRIP
  FROM @RAW.TAXI.INT_STAGE PATTERN='.*green.*parquet' FILE_FORMAT=(FORMAT_NAME=RAW.TAXI.PARQUET_FMT);
```

> **Also import the Lookup/Zone tables** into `RAW` (seed via dbt or load as raw):
- `RAW.TAXI.TAXI_ZONE_LOOKUP`
- `RAW.TAXI.PAYMENT_TYPE`
- `RAW.TAXI.RATE_CODE`
- `RAW.TAXI.VENDOR`
- `RAW.TAXI.TRIP_TYPE`

---

## 🛠️ 3) dbt project setup in VS Code

1) **Initialize dbt** (e.g., `dbt init nyc_taxi`), choose **Snowflake** profile.  
2) Configure `profiles.yml` with account, role, warehouse, database `RAW`, and your target schema for models (e.g., `ANALYTICS`).  
3) In VS Code, organize models like this:

```
models/
  ├─ staging/                 # ephemeral source models
  │   ├─ src_yellow_trip.sql
  │   ├─ src_green_trip.sql
  │   ├─ src_payment_type.sql
  │   ├─ src_rate_code.sql
  │   ├─ src_vendor.sql
  │   └─ src_trip_type.sql
  ├─ dim/
  │   ├─ dim_borough.sql
  │   ├─ dim_payment_type.sql
  │   ├─ dim_rate_code.sql
  │   ├─ dim_vendor.sql
  │   ├─ DIM_TAXI_ZONE_LOOKUP.sql
  │   └─ dim_trip_type.sql
  ├─ fct/
  │   ├─ fct_yellow_cleansed.sql
  │   └─ fct_green_cleansed.sql
  └─ seeds/
      └─ taxi_zone_lookup.csv (or .yml for external reference)
```

> ✅ **This repo includes model SQL files:**  
> `fct_green_cleansed.sql`, `fct_yellow_cleansed.sql`, `dim_trip_type.sql`, `dim_payment_type.sql`, `DIM_TAXI_ZONE_LOOKUP.sql`, `dim_borough.sql`, `dim_vendor.sql`, `dim_rate_code.sql`, and the source models `src_*` for payment, rate code, vendor, trip type, yellow, green.

### Why **ephemeral** sources?
- Staging models `src_*` (e.g., `src_yellow_trip`, `src_green_trip`) are **materialized as `ephemeral`** to push logic **into the downstream models** at compile time.  
- Benefits: zero staging tables, faster dev cycles, clearer lineage, and fewer objects in Snowflake.

**Example `dbt_project.yml` excerpt:**
```yml
models:
  nyc_taxi:
    staging:
      +materialized: ephemeral
    dim:
      +materialized: view    # or table
    fct:
      +materialized: table
```

**Run & test:**
```bash
dbt seed        # loads taxi zone lookups if used as seed
dbt run         # builds dims & facts (ephemeral sources inlined)
dbt test        # executes schema & data tests
dbt docs generate && dbt docs serve  # browse lineage & docs
```

---

## 🧭 4) Geospatial Enrichment via Wikidata SPARQL

I extracted **precise latitude/longitude for boroughs** to improve mapping accuracy in Power BI.

Example query (simplified):

```sparql
SELECT ?borough ?boroughLabel ?coord WHERE {
  VALUES ?borough { wd:Q18424 wd:Q18435 wd:Q18438 wd:Q18442 wd:Q18426 } # NYC borough Q-ids
  ?borough wdt:P625 ?coord .
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
```

- Results were joined to the zone/borough dimension to produce **exact points** for **centroid mapping** and disambiguation.  
- Stored in a lookup table (e.g., `RAW.TAXI.BOROUGH_COORDS`) and joined in `dim_borough.sql`.

---

## 🧩 5) Dimensional Model (Star)

**Dimensions** *(examples)*  
- `dim_borough` (enriched with Wikidata lat/long)  
- `dim_payment_type`, `dim_rate_code`, `dim_vendor`, `dim_trip_type`, `DIM_TAXI_ZONE_LOOKUP`

**Facts**  
- `fct_yellow_cleansed` and `fct_green_cleansed` aggregate and standardize trips from raw sources, applying data type normalization, timestamp casting, and business logic.

> Models in this repo (representative):
- `fct_green_cleansed.sql`
- `fct_yellow_cleansed.sql`
- `dim_trip_type.sql`
- `dim_payment_type.sql`
- `DIM_TAXI_ZONE_LOOKUP.sql`
- `dim_borough.sql`
- `dim_vendor.sql`
- `dim_rate_code.sql`
- `src_payment_type.sql`, `src_rate_code.sql`, `src_vendor.sql`, `src_trip_type.sql`
- `src_yellow_trip.sql`, `src_green_trip.sql`

---

## 🔎 6) Data Quality & Validations (dbt tests)

- **Schema tests:** `not_null`, `unique`, `accepted_values` on keys and enums.
- **Referential integrity:** FK checks from facts → dims (e.g., `payment_type_id`, `rate_code_id`, `vendor_id`, `zone_id`).
- **Freshness** on sources (optional): ensure recent partitions are present.
- **Row-level logic:** negative fares filtered, invalid lat/long dropped, trip_distance > 0, etc.

Example YAML snippet:
```yml
models:
  - name: fct_yellow_cleansed
    tests:
      - dbt_utils.expression_is_true:
          expression: "fare_amount >= 0 AND trip_distance >= 0"
    columns:
      - name: trip_id
        tests: [unique, not_null]
      - name: payment_type_id
        tests:
          - relationships:
              to: ref('dim_payment_type')
              field: payment_type_id
```

---

## 📊 7) Power BI — Analytical Layer

**Modeling:**
- Import `dim_*` and `fct_*` tables from Snowflake.
- Create relationships: facts → dims (keys: vendor, rate, payment, trip type, pickup/dropoff zone, borough).
- Hide surrogate keys from the report view; surface readable attributes.

**Design choices (recruiter‑friendly):**
- **KPI strip**: Total Trips, Gross Revenue, Avg Fare, Avg Trip Distance, Tip %, Avg Trip Time.
- **Time intelligence** (DAX): MTM/YoY deltas and sparklines.
- **Geo visuals**: Map of trips and revenue by **borough** using enriched **lat/long**; filterable by service (Yellow/Green), hour of day, payment type.
- **Behavioral insights**: Hourly heatmap of pickups, Tip% distribution, Vendor market share pie, Top zones by net revenue.
- **Bookmarks** for “Executive”, “Ops”, and “Geo” views.

**Example DAX (Avg Tip %):**
```DAX
Avg Tip % = DIVIDE( SUM(Fact[tip_amount]), SUM(Fact[fare_amount]) )
```

---

## ✅ What I checked on the fact tables

I ran validations to ensure production readiness:
- **Row counts** vs. raw staging (no unexpected drop).
- **Monetary sanity**: totals of `fare_amount`, `tip_amount`, `total_amount` within expected bounds.
- **Key coverage**: 100% join rate to dimensions (no orphaned IDs).
- **Temporal**: pickup < dropoff; timezone consistent; derived hour-of-day populated.
- **Geospatial**: valid coordinates and borough/zone linkage; enriched lat/long present.

---

## 🗂️ Repository Highlights (files you’ll find here)

- **Facts**
  - `fct_yellow_cleansed.sql`
  - `fct_green_cleansed.sql`
- **Dimensions**
  - `dim_borough.sql` (includes Wikidata coords)
  - `DIM_TAXI_ZONE_LOOKUP.sql`
  - `dim_payment_type.sql`
  - `dim_rate_code.sql`
  - `dim_vendor.sql`
  - `dim_trip_type.sql`
- **Sources (staging, ephemeral)**
  - `src_yellow_trip.sql`
  - `src_green_trip.sql`
  - `src_payment_type.sql`
  - `src_rate_code.sql`
  - `src_vendor.sql`
  - `src_trip_type.sql`
- **Config**
  - `dbt_project.yml`

---

## 🚀 How to run this project (quick start)

1. **Python ingest**
   - Create a virtualenv, install deps (`pandas`, `pyarrow`, `requests`, `snowflake-connector-python` or `snowsql`).
   - Run the scraper to download monthly files to `data/ingest`.

2. **Snowflake**
   - Create `RAW` db, stage, and load using the SQL above.
   - (Optional) Create a `TRANSFORM` or `ANALYTICS` schema for dbt models.

3. **dbt**
   - Set up `profiles.yml` for Snowflake connection.
   - `dbt seed` (to load taxi zones if used as seed).
   - `dbt run` then `dbt test`.
   - `dbt docs generate && dbt docs serve` to browse lineage.

4. **Power BI**
   - Connect to Snowflake; import `fct_*` and `dim_*`.
   - Build visuals (see the design section) and publish.

---

## 🎤 Results & sample insights (story your stakeholders will hear)

- **Rush‑hour pickup spikes** (7–9 AM, 5–7 PM) with **higher average fares** and **lower Tip%** vs. off‑peak, suggesting **price‑sensitive commuting** vs. **experience‑focused leisure**.
- **Credit card share** higher for airport trips; **cash share** clusters in specific boroughs/zones—**targeted driver training** and **POS reliability** improve conversion.
- **Top 10 pickup zones** account for a disproportionate share of revenue—**dispatch optimization** can reduce deadhead time.
- **Vendor differences** in average trip distance/time hint at **coverage strategies** and potential **service‑level agreements**.

> These insights are designed to show how I move from raw data to **actionable, operational recommendations**.

---

## 🔒 Security & cost controls

- Snowflake **AUTO_SUSPEND** on small warehouse; scale up only for backfills.
- Principle of least privilege (role for dbt, role for BI).
- Ephemeral staging reduces storage footprint.
- Incremental models (optional) for rolling loads.

---

## 📌 Notes for reviewers (what to look for)

- Clear **lineage** from `RAW` → `ephemeral src_*` → dims/facts.
- Thoughtful **naming conventions** and **YAML documentation**.
- **Tests** that reflect business rules, not just mechanics.
- Clean **Power BI** design aligned to end‑users (execs and ops).

---

## 📫 Contact

If you’d like a quick walkthrough or want to discuss trade‑offs (incremental strategy, partitioning, streaming, geospatial options), I’m happy to chat.

---

_Thanks for reviewing!_  
**— Your Name**
