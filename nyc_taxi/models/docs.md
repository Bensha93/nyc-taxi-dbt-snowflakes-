{% docs yellow_taxi_overview %}

# Yellow Taxi Trip Data

This dataset contains trip records from iconic yellow taxis operating in NYC. Yellow taxis are the traditional NYC taxicabs authorized to pick up street hails throughout all five boroughs, but primarily operate in Manhattan and at the airports.

## Data Source
- **Provider:** NYC Taxi & Limousine Commission (TLC)
- **Update Frequency:** Monthly
- **Coverage:** All NYC Yellow Taxi trips
- **Time Range:** Historical data from 2009 to present

## Service Area
Yellow taxis can pick up passengers anywhere in NYC:
- **Primary Service:** Manhattan (all areas)
- **Airport Service:** JFK and LaGuardia airports
- **Outer Boroughs:** Available but less common
- **Special Rates:** Airport fixed rates available

## Data Quality
This cleaned version includes comprehensive data validation:
- Removes invalid timestamps and negative values
- Filters unrealistic trip distances, durations, and speeds
- Validates fare component calculations including airport fees
- Excludes future-dated records
- Handles missing values with appropriate defaults

{% enddocs %}

{% docs green_taxi_overview %}

# Green Taxi Trip Data

This dataset contains trip records from green taxis (street-hail livery vehicles) operating in NYC. Green taxis are authorized to pick up passengers in outer boroughs and upper Manhattan (north of West 110th St and East 96th St), as well as anywhere in NYC if the trip originated outside of the excluded zones.

## Data Source
- **Provider:** NYC Taxi & Limousine Commission (TLC)
- **Update Frequency:** Monthly
- **Coverage:** All NYC Green Taxi trips
- **Time Range:** Historical data from 2013 to present

## Data Quality
This cleaned version includes comprehensive data validation:
- Removes invalid timestamps and negative values
- Filters unrealistic trip distances, durations, and speeds
- Validates fare component calculations
- Excludes future-dated records
- Handles missing values with appropriate defaults

{% enddocs %}

{% docs pickup_location_zone %}

Pickup location based on the TLC Taxi Zone geography. Each zone represents a specific area of NYC with the following characteristics:

- **Zone 1-103:** Manhattan zones
- **Zone 104-177:** Brooklyn zones  
- **Zone 178-210:** Queens zones
- **Zone 211-245:** Bronx zones
- **Zone 246-261:** Staten Island zones
- **Zone 264-265:** New Jersey zones

**Yellow Taxis:** Can pick up anywhere in NYC, with primary service in Manhattan and airports.
**Green Taxis:** Limited to outer boroughs and upper Manhattan (north of 96th St East/110th St West).

{% enddocs %}

{% docs dropoff_location_zone %}

Dropoff location based on the TLC Taxi Zone geography. Both yellow and green taxis can drop off passengers anywhere in the five boroughs, regardless of pickup location restrictions.

Zones follow the same numbering system as pickup locations.

{% enddocs %}

{% docs calculated_metrics %}

## Trip Duration Metrics
- **trip_minutes:** Total duration in minutes (pickup to dropoff)
- **trip_hours:** Total duration in decimal hours

## Speed and Efficiency
- **mph:** Average speed calculated as distance/time
- **fare_per_mile:** Base fare efficiency metric (fare_amount/trip_distance)

All metrics are filtered to remove unrealistic outliers that may indicate data collection errors.

{% enddocs %}

{% docs payment_types %}

Payment method classification:

| Code | Method | Description |
|------|---------|-------------|
| 1 | Credit Card | Most common, includes automatic tip calculation |
| 2 | Cash | Tips not captured in tip_amount field |
| 3 | No Charge | Promotional or comp trips |
| 4 | Dispute | Payment disputed or voided |
| 5 | Unknown | Missing or unrecognized payment type |

{% enddocs %}

{% docs fare_breakdown %}

## Fare Components

The total_amount represents the sum of all fare components:

**Common to Both Yellow and Green:**
- **fare_amount:** Base time and distance charge
- **tip_amount:** Gratuity (credit card only)
- **tolls_amount:** Bridge and tunnel tolls
- **extra:** Rush hour and overnight surcharges
- **mta_tax:** Standard $0.50 MTA tax
- **improvement_surcharge:** $0.30 improvement fee
- **congestion_surcharge:** Manhattan congestion pricing
- **cbd_congestion_fee:** Central Business District fee

**Yellow Taxi Only:**
- **Airport_fee:** $1.25 fee for airport pickups (LGA/JFK)

All amounts are validated to ensure mathematical consistency within 1 cent tolerance.

{% enddocs %}

{% docs yellow_taxi_surcharges %}

## Yellow Taxi Specific Fees

**Congestion Surcharge:** $2.50 for trips that begin, end, or pass through Manhattan south of 96th Street.

**Airport Fee:** $1.25 surcharge for trips originating at LaGuardia or JFK airports.

**Rush Hour Extra:** $1.00 surcharge Monday-Friday 4:00-8:00 PM.

**Overnight Extra:** $0.50 surcharge 8:00 PM - 6:00 AM daily.

{% enddocs %}