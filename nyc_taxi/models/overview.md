{% docs __overview__ %}

# NYC Taxi Data Warehouse

## Project Overview

![input schema](nyc_taxi\assets\NYC-TLC-ERD.png)

Welcome to the NYC Taxi Data Warehouse - a comprehensive analytics platform built on NYC Taxi & Limousine Commission (TLC) trip record data. This data warehouse provides clean, validated, and analysis-ready datasets for understanding taxi operations, passenger behavior, and urban mobility patterns across New York City.

## 🚖 Data Sources

### Yellow Taxi Data
**Coverage:** All five boroughs, with primary service in Manhattan and airports  
**Service Period:** 2020 - Present  
**Volume:** ~200M+ trips annually  
**Special Features:** Airport fees, higher service density in Manhattan

### Green Taxi Data  
**Coverage:** Outer boroughs and upper Manhattan (north of 96th St E/110th St W)  
**Service Period:** 2020 - Present  
**Volume:** ~20M+ trips annually  
**Special Features:** Designed to serve underserved areas



---

## Key Metrics & KPIs

| Metric | Description | Business Value |
|--------|-------------|----------------|
| **Trip Volume** | Daily/Monthly trip counts by taxi type | Operational capacity planning |
| **Revenue Analysis** | Fare breakdowns, tip patterns, surcharge impact | Financial performance |
| **Geographic Patterns** | Popular pickup/dropoff zones, route analysis | Service optimization |
| **Efficiency Metrics** | Trip duration, speed, fare per mile | Operational efficiency |
| **Payment Trends** | Cash vs. credit card usage patterns | Technology adoption |

---

## Data Architecture

### Data Flow
```
Raw TLC Data → Data Quality Filters → Calculated Metrics → Analytics-Ready Tables
```

### Data Quality Standards
- **Completeness:** Remove records with missing critical fields
- **Validity:** Filter unrealistic distances, speeds, and fare amounts  
- **Consistency:** Validate fare component calculations
- **Timeliness:** Exclude future-dated records
- **Accuracy:** Apply business rule validations

### Quality Filters Applied
- Trip distance: 0-100 miles
- Trip duration: 1 minute - 8 hours  
- Speed: 1-80 mph (when calculable)
- Passenger count: 1-8 passengers
- Fare per mile: $0.50-$20.00

---

## Key Tables & Usage

### Fact Tables

#### `fct_yellow_cleansed`
**Purpose:** Clean yellow taxi trip data ready for analysis  
**Key Features:** 
- Airport fee tracking
- Comprehensive fare validation
- Speed and efficiency metrics
- Deduplication via surrogate keys

**Common Use Cases:**
- Manhattan traffic analysis
- Airport service patterns
- Revenue optimization
- Peak hour analysis

#### `fct_green_cleansed`  
**Purpose:** Clean green taxi trip data ready for analysis  
**Key Features:**
- Outer borough focus
- Trip type classification (street-hail vs dispatch)
- Service area compliance validation

**Common Use Cases:**
- Outer borough service analysis
- Underserved area coverage
- Green taxi performance vs yellow
- Dispatch vs street-hail patterns

### Dimension Tables
- `dim_taxi_zone_lookup`: Geographic zone definitions
- `dim_vendor`: Taxi technology providers
- `dim_payment_type`: Payment method classifications  
- `dim_rate_code`: Fare structure definitions
- `dim_trip_type`: Trip classification (green taxi only)

---

## Business Applications

### Operations & Planning
- **Fleet Management:** Optimize taxi distribution across zones
- **Service Planning:** Identify underserved areas and peak demand periods
- **Route Optimization:** Analyze traffic patterns and trip efficiency

### Financial Analysis
- **Revenue Optimization:** Understand fare structures and pricing impact
- **Cost Analysis:** Break down operational costs per trip/zone
- **Profitability:** Compare yellow vs green taxi performance

### Regulatory Compliance
- **Service Standards:** Monitor service quality and coverage
- **Fare Compliance:** Validate proper fare calculations
- **Geographic Compliance:** Ensure green taxis operate within authorized zones

### Market Intelligence
- **Demand Forecasting:** Predict trip volumes and seasonal patterns
- **Competitive Analysis:** Benchmark against ride-sharing services
- **Urban Planning:** Inform transportation policy decisions

---

## Data Governance

### Data Quality Monitoring
- **Daily Tests:** Automated data quality checks on key metrics
- **Freshness Monitoring:** Alerts for delayed data updates
- **Volume Validation:** Detect unusual changes in trip volumes
- **Business Rule Validation:** Ensure fare calculations remain accurate

### Documentation Standards
- **Column-Level Documentation:** Every field has business context
- **Data Lineage:** Clear visibility into data transformations
- **Test Coverage:** Comprehensive validation rules documented
- **Change Management:** Version control for schema changes

### Access & Security  
- **Role-Based Access:** Different permission levels for different users
- **Data Classification:** Sensitive fields appropriately protected
- **Audit Trail:** Track data access and usage patterns

---

## Getting Started

### For Analysts
1. **Explore the Data:** Start with `fct_yellow_cleansed` and `fct_green_cleansed`
2. **Join with Dimensions:** Use taxi zones, payment types, and vendor lookups
3. **Filter by Date:** Focus on recent months for current patterns
4. **Validate Results:** Cross-check with known business metrics

### For Data Engineers
1. **Review Models:** Understand the incremental strategies and transformations
2. **Monitor Tests:** Check data quality test results regularly
3. **Performance Tuning:** Optimize queries for large datasets
4. **Schema Evolution:** Follow change management processes

### For Business Users
1. **Dashboard Access:** Connect to pre-built analytics dashboards
2. **Report Templates:** Use standardized report formats
3. **KPI Definitions:** Reference the metrics glossary
4. **Support:** Contact the analytics team for custom analysis

---

## Technical Specifications

### Infrastructure
- **Platform:** Snowflake Data Warehouse
- **Orchestration:** dbt (Data Build Tool)
- **Processing:** Incremental daily updates
- **Storage:** Optimized for analytical workloads

### Performance Features
- **Incremental Processing:** Only new/changed records processed daily
- **Partitioning:** Optimized by pickup date for query performance
- **Clustering:** Geographic clustering for location-based queries
- **Caching:** Frequently accessed aggregations pre-computed

### SLA Commitments
- **Availability:** 99.5% uptime during business hours
- **Query Performance:** 95% of queries under 30 seconds
- **Support Response:** 4-hour response for critical issues

{% enddocs %}