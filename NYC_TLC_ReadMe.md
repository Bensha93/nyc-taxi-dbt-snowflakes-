# NYC Taxi Analytics — End‑to‑End Data Engineering (Python → Snowflake → dbt)

> **Hire‑me highlight:** This project demonstrates a complete, production‑style analytics pipeline: web scraping, cloud data warehousing, semantic modeling with dbt, data quality testing, and geospatial enrichment from Wikidata — all reproducible from scratch.

---

## ⚡ What you’ll see at a glance
- **Ingestion:** Python scrapes NYC TLC trip data and pushes it to **Snowflake** (`RAW` database).
- **Modeling:** **dbt** transforms raw data into a **clean star schema** (dim/fact) ready for BI.
- **Governance:** Ephemeral **source** models, **seeded** zone lookup, and robust **tests**.
- **Enrichment:** Exact **latitude/longitude** per NYC **borough** via **SPARQL** from Wikidata.
- **Reproducible:** Clear, copy‑pasteable commands, folder structure, and config examples.

---

## 🧭 Architecture

```
NYC TLC Website ─┐
                  ├─(Python: requests/pandas)─► Snowflake (DB: RAW, Schema: PUBLIC)
Wikidata SPARQL ─┘                                      │
                                                        ▼
                                                 dbt (in VS Code)
                                   ┌───────────────┬──────────────────────┐
                                   │               │                      │
                              Seeds/Lookups     Ephemeral Sources       Dim & Fact Models
                             (Taxi Zone Lookup) (src_* models)          (dim_*, fct_*)
                                   │               │                      │
                                   └───────────────┴──────────► Tested, Documented Warehouse
```

---

## 📦 Tech Stack
**Python**, **pandas**, **requests**, **snowflake‑connector‑python**  
**Snowflake** (databases, warehouses, stages, roles)  
**dbt** (sources, seeds, ephemeral models, tests, documentation) in **VS Code**  
**SPARQL** (Wikidata) for borough geolocation enrichment

---

## 1) Data Sourcing & Scraping (Python)

**Goal:** Fetch TLC trip files (Yellow + Green) programmatically and prepare them for Snowflake.

Key steps:
1. Build a list of TLC file URLs (CSV/Parquet) for target months/years.
2. Stream‑download → pandas load → dtype cleanup (timestamps, numeric fares, passenger count).
3. Normalize column names to snake_case; keep **schema parity** across Yellow/Green where possible.
4. (Optional) Partition locally (e.g., by year/month) to control load granularity.
5. Use `snowflake-connector-python` to upload into Snowflake `RAW.PUBLIC` tables.

**Skeleton:**
```python
import pandas as pd
import requests, io
import snowflake.connector as sf

def fetch_csv(url):
    b = requests.get(url, timeout=60).content
    return pd.read_csv(io.BytesIO(b))

def write_to_snowflake(df, table, conn_params):
    with sf.connect(**conn_params) as con:
        cs = con.cursor()
        # create table if not exists (minimal schema)
        cs.execute(f'''
            create table if not exists raw.public.{table} as
            select * from (select * from values(1)) where 1=0
        ''')
        # simple PUT/COPY or write via write_pandas (preferred)
        from snowflake.connector.pandas_tools import write_pandas
        write_pandas(con, df, f"RAW.PUBLIC.{table}", auto_create_table=True)
```

> **Result:** `RAW.PUBLIC.YELLOW_TRIP` and `RAW.PUBLIC.GREEN_TRIP` are populated and ready for dbt.

---

## 2) Snowflake Setup (fresh environment)

```sql
-- Roles & warehouse
create warehouse if not exists compute_wh with warehouse_size='XSMALL' auto_suspend=60 auto_resume=true;
use warehouse compute_wh;

-- Raw landing database
create database if not exists raw;
use database raw;
use schema public;

-- (Optional) File stage for bulk loads
create stage if not exists raw_stage file_format=(type=csv field_optionally_enclosed_by='"' skip_header=1);
```

Lookup/seed tables are kept small and fast; they live in the same `RAW.PUBLIC` for simplicity.

---

## 3) dbt in VS Code — project wiring

1. **Install dbt adapter** for Snowflake and create a **profile**:
   ```yaml
   # ~/.dbt/profiles.yml
   nyc_taxi:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: <your_account>
         user: <your_user>
         password: <your_password>
         role: <your_role>
         database: RAW
         warehouse: COMPUTE_WH
         schema: PUBLIC
         threads: 4
         client_session_keep_alive: False
   ```

2. **Initialize dbt project** (in the repo root):
   ```bash
   dbt init nyc_taxi
   # open folder in VS Code, install Python/dbt extensions as needed
   ```

3. **Sources** (ephemeral) and **Seeds** in `models/`:
   - `src_yellow_trip.sql` (materialized: **ephemeral**) → selects from `raw.public.yellow_trip`
   - `src_green_trip.sql`  (materialized: **ephemeral**) → selects from `raw.public.green_trip`
   - **Seed:** `taxi_zone_lookup.csv` → `dim_taxi_zone_lookup`

4. **Lookups (source dims)** created from raw/CSV:
   - `src_payment_type.sql`
   - `src_rate_code.sql`
   - `src_vendor.sql`
   - `src_trip_type.sql`

5. **Dimensions** (cleansed/enriched):
   - `dim_payment_type.sql`
   - `dim_rate_code.sql`
   - `dim_vendor.sql`
   - `dim_trip_type.sql`
   - `dim_borough.sql` (with exact `lat/long` from SPARQL merge)
   - `dim_taxi_zone_lookup.sql` (seeded and normalized)

6. **Facts:**
   - `fct_yellow_cleansed.sql`
   - `fct_green_cleansed.sql`

> The uploaded SQL model files in this repo mirror the items above, so you can open and review each transformation step in one place.

---

## 4) Modeling strategy (what & why)

### Ephemeral **sources** (`src_*`)
- Materialized as **ephemeral** to **inline CTEs** during compilation → faster dev cycles and cleaner DAGs.
- Standardizes raw columns (types, names), e.g. `pickup_datetime`, `dropoff_datetime`, `fare_amount`, `trip_distance`.

### Dimensions (`dim_*`)
- Small tables; **one row per natural key** (e.g., per code, per zone, per borough).
- Provide **human‑readable** attributes and **consistent keys** for facts.
- Borough geospatial enrichment enables mapping and radius analyses.

### Facts (`fct_*_cleansed`)
- Row‑level trip facts (Yellow/Green) with data quality rules:
  - Drop negative fares/distance, unrealistic durations, invalid coordinates.
  - Join to dims for rate code, payment, vendor, trip type, and zone metadata.
- Output is **BI‑ready** and friendly to partitioning by date.

**Example dbt model config (ephemeral source):**
```sql
{{ config(materialized='ephemeral') }}

with src as (
  select * from raw.public.yellow_trip
)
, normalized as (
  select
    cast(pickup_datetime as timestamp)   as pickup_ts,
    cast(dropoff_datetime as timestamp)  as dropoff_ts,
    cast(passenger_count as int)         as passenger_count,
    cast(trip_distance as float)         as trip_distance,
    cast(fare_amount as numeric(10,2))   as fare_amount,
    payment_type, rate_code_id, vendor_id, trip_type,
    pulocationid, dolocationid
  from src
)
select * from normalized
```

---

## 5) Geospatial Enrichment with Wikidata (SPARQL)

**Goal:** Add precise borough centroids to support mapping & spatial joins.

**SPARQL pattern used:**
```sparql
# Borough -> label + coordinates (EPSG:4326)
SELECT ?borough ?boroughLabel ?coord WHERE {
  ?borough wdt:P31 wd:Q18424.   # instance of borough of NYC
  ?borough wdt:P625 ?coord.     # coordinate location
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
```

The results are parsed from the Wikidata endpoint (JSON), then written to `RAW.PUBLIC` and transformed into `dim_borough` in dbt, giving each borough a `latitude`, `longitude`, and surrogate key.

---

## 6) Data Quality & Tests

- **Generic tests** in `schema.yml`: `not_null`, `unique`, `accepted_values`, `relationships`.
- **Business rules** embedded in SQL for the fact models (e.g., `trip_distance > 0`, `fare_amount >= 0`).
- **Runbook:**
  ```bash
  dbt deps
  dbt seed           # loads taxi zone lookup
  dbt run            # builds dims & facts
  dbt test           # ✅ run checks on the fact tables & dims
  ```

Common tests on facts:
- keys present: `pulocationid`, `dolocationid` reference taxi zones
- timestamps not null and `dropoff_ts >= pickup_ts`
- non‑negative fares, surcharges, taxes
- relationships to `dim_*` are valid

---

## 7) Example analytics (ready for BI)

- **Utilization:** Trips by hour/day; borough origin/destination matrices.
- **Revenue:** Average fare per mile; tip percentage by payment type.
- **Quality:** Outlier detection (extreme distances vs. durations).
- **Geo:** Heatmaps by pickup density; top inter‑borough flows.

Example query (average fare per mile by borough pair & hour):
```sql
select
  p.borough as pickup_borough,
  d.borough as dropoff_borough,
  date_trunc('hour', f.pickup_ts) as pickup_hour,
  sum(f.fare_amount) / nullif(sum(f.trip_distance),0) as avg_fare_per_mile
from {{ ref('fct_yellow_cleansed') }} f
join {{ ref('dim_taxi_zone_lookup') }} zp on f.pulocationid = zp.locationid
join {{ ref('dim_taxi_zone_lookup') }} zd on f.dolocationid = zd.locationid
join {{ ref('dim_borough') }} p on zp.borough = p.borough_name
join {{ ref('dim_borough') }} d on zd.borough = d.borough_name
group by 1,2,3
order by 3,1,2;
```

---

## 8) Project Layout (key items)

```
.
├── models/
│   ├── sources/
│   │   ├── src_yellow_trip.sql        # ephemeral
│   │   ├── src_green_trip.sql         # ephemeral
│   │   ├── src_payment_type.sql       # source lookup
│   │   ├── src_rate_code.sql          # source lookup
│   │   ├── src_vendor.sql             # source lookup
│   │   └── src_trip_type.sql          # source lookup
│   ├── dims/
│   │   ├── dim_payment_type.sql
│   │   ├── dim_rate_code.sql
│   │   ├── dim_vendor.sql
│   │   ├── dim_trip_type.sql
│   │   ├── dim_borough.sql
│   │   └── dim_taxi_zone_lookup.sql
│   ├── facts/
│   │   ├── fct_yellow_cleansed.sql
│   │   └── fct_green_cleansed.sql
│   └── schema.yml                     # tests & docs
├── seeds/
│   └── taxi_zone_lookup.csv           # Taxi Zone Seed
├── scripts/
│   ├── ingest_tlc.py                  # scrape & load to Snowflake RAW
│   └── wikidata_boroughs.py           # SPARQL enrichment loader
└── README.md
```

---

## 9) How to Run (reproduce on your machine)

```bash
# 0) Python env
python -m venv .venv && source .venv/bin/activate
pip install pandas requests snowflake-connector-python dbt-snowflake

# 1) Environment variables (optional)
export SNOWFLAKE_ACCOUNT=...
export SNOWFLAKE_USER=...
export SNOWFLAKE_PASSWORD=...
export SNOWFLAKE_ROLE=...
export SNOWFLAKE_WAREHOUSE=COMPUTE_WH
export SNOWFLAKE_DATABASE=RAW
export SNOWFLAKE_SCHEMA=PUBLIC

# 2) Scrape & load
python scripts/ingest_tlc.py
python scripts/wikidata_boroughs.py

# 3) Build & test
dbt deps
dbt seed
dbt run
dbt test
```

---

## 🔍 Why this project matters

- Shows **end‑to‑end ownership**: ingestion → warehousing → modeling → testing → analytics.
- Uses **best practices**: ephemeral sources, seeds for small reference data, clean star schema.
- Demonstrates **cloud data skills** (Snowflake), modern **ELT** with dbt, and **data quality** rigor.
- Adds **geospatial context** recruiters love to see in product analytics and ops use‑cases.

---

## 📈 Results & next steps

- Warehouse tables that are **immediately consumable** by BI tools (e.g., Mode, Tableau, Hex, Power BI).
- Clear testing story for **trustworthy metrics**.
- Easy extensions: monthly auto‑ingest, coverage for FHVs, geofencing insights (e.g., airports), CI/CD with `dbt build` on PRs.

> If you’d like, I can also provide a **short Loom‑style walkthrough** script and a **dash notebook** exploring top insights.

---

### Credits
NYC Taxi & Limousine Commission (TLC) Open Data. Wikidata contributors (SPARQL endpoint).

