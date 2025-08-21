

# NYC Taxi Analytics Pipeline (dbt + Snowflake)
nyc taxi and limousine commission (dbt project   snowflakes-db)

## ⚠️ Status: Under Construction 🚧
This is an **ongoing project** where I’m building a scalable analytics pipeline in **dbt** using **NYC TLC Taxi Trip Records** on **Snowflake**.  
The project is actively being developed — expect regular updates, new models, and documentation improvements.

---

## Project Goal
Transform raw NYC Taxi trip logs into a trusted, analytics-ready **data mart**.  
This data mart will empower stakeholders to analyze:

- Ridership trends  
- Revenue performance  
- Service quality across Yellow, Green, and FHV taxi services  

Ultimately supporting **operational decision-making** and **public transparency**.

---

## Objectives

### 🔹 Data Ingestion & Standardization
- Ingest Yellow, Green, and FHV trip data from raw Snowflake tables.  
- Standardize column names, formats, and data types across services.  

### 🔹 Data Quality & Governance
- Apply **dbt tests** for completeness, uniqueness, and validity of trip IDs, location IDs, and payment types.  
- Remove duplicates and filter invalid/suspicious trips (e.g., negative fares, zero distances).  

### 🔹 Dimensional Modeling
- Build **fact and dimension tables** (Trips, Payment Types, Taxi Zones, Calendar, etc.).  
- Implement **incremental loading** for efficient updates.  

### 🔹 Business Insights & Transparency
- Aggregate metrics such as:
  - Trips per day  
  - Total revenue  
  - Average fare  
  - Tip percentage (by zone and service type)  
- Expose these models to a **BI tool** (e.g., Power BI) via **dbt exposures**.  

### 🔹 Scalability & Maintainability
- Use **dbt snapshots** to track changes in reference data over time.  
- Document all **sources, models, and tests** for future analysts.  

---

## 🛠 Tech Stack
- **Snowflake** — cloud data warehouse  
- **dbt** — transformation, testing, and documentation  
- **Power BI** — reporting & visualization  

---

## Data Sources
- NYC TLC raw tables hosted in Snowflake:
  - `YELLOW_TRIP_RAW`  
  - `GREEN_TRIP_RAW`  
  - `PAYMENT_TYPE`  
  - `TRIP_TYPE`  
  - `TAXI_ZONE_LOOKUP`  
  - `VENDOR`  
  - `RATE_CODE`  

---

##  Deliverables (In Progress)
- Trusted **data mart** in Snowflake  
- dbt models with **tests, documentation, and exposures**  
- Analytics-ready tables for BI and public reporting  

---

## Roadmap
- [x] Initial Snowflake setup (database, warehouse, schemas)  
- [x] Ingest raw TLC data  
- [x] Build staging models in dbt  
- [x] Add data quality tests  
- [x] Create fact & dimension models  
- [ ] Define dbt exposures for BI  
- [ ] Deploy reporting dashboards  

---

## Note for Recruiters / Visitors
This repository is **actively being built**.  
Think of it as a **living portfolio project** showcasing modern data engineering practices with **Snowflake + dbt + BI**.  

If you’d like to learn more about the project or discuss data engineering opportunities, feel free to connect!  
