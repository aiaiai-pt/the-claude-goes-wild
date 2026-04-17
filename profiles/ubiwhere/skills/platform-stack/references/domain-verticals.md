# Domain Verticals Reference (UBP)

## Verticals and Their Data Sources

| Vertical | Iceberg Domain | External Sources | Typical Sensors | NGSI-LD Publication Types |
|----------|---------------|-----------------|-----------------|--------------------------|
| **Mobility** | `mobility` | GTFS providers, municipal fleet GPS | GPS trackers, loop detectors | Vehicle, TrafficFlowObserved |
| **Energy** | `energy` | E-Redes, DGEG | Smart meters (LoRaWAN) | EnergyConsumptionObserved |
| **Water** | `water` | AdRA, SNIRH | Flow sensors, quality probes | WaterQualityObserved |
| **Waste** | `waste` | Municipal waste operators | Fill-level sensors (LoRaWAN) | WasteContainer |
| **Incidents** | `incidents` | ANEPC, CDOS | Citizen reports, CICLOPE | Alert, IncidentReport |
| **IoT/LoRaWAN** | `iot` | ChirpStack v4 | Any LoRaWAN device | Device, DeviceModel |
| **Environment** | `environment` | IPMA, QualAr, APA | Environmental stations | AirQualityObserved, WeatherObserved |
| **Parking** | `parking` | Municipal parking operators | Occupancy sensors | ParkingSpot |
| **POI** | `poi` | Tourism offices, business registries | — | PointOfInterest |
| **Tourism** | `tourism` | Tourism indicators providers | — | TouristInformation |
| **Accommodation** | `accommodation` | Booking platforms | — | Accommodation |
| **Agriculture** | `agri` | Municipal agri programmes | Soil/climate sensors | AgriCrop |
| **Hazard** | `hazard` | ANPC, CNOS | Weather-driven | Alert |
| **Transport-Pax** | `transport-pax` | GTFS, Transit feeds | — | PublicTransport |

> ⚠ **NGSI-LD publication is BLOCKED** — Orion-LD is disabled in all production
> instances. Do not wire new NGSI-LD publication until **ADR-001** resolves
> (see AP-5 / G3). The NGSI-LD types listed above are **reference** for future
> integration only.

## Domain Naming

- Iceberg namespace: `{instance}.{layer}.{domain}` with `domain` in **snake_case**
- GCS path entity segment: **snake_case** (e.g., `air_quality`, NOT `air-quality`)
- Tenant slug: **kebab-case** (e.g., `oliveira-do-bairro`)

Per canonical grammar §10.

## Data Flow per Vertical

```
External Source → dlt source (Dagster-orchestrated)
    → Bronze: {instance}.bronze.{vertical}.{source}_raw
    → Silver: {instance}.silver.{vertical}.{entity}_clean
    → Gold:   {instance}.gold.{vertical}.{entity}_kpi / {entity}_daily
    → Query: Trino → Metabase dashboard / FastAPI service / Frontend
    [→ Publication: Dagster job → Orion-LD — BLOCKED on ADR-001]
```

## Iceberg Namespace Convention per Vertical
```
{instance}.bronze.mobility.vehicle_positions_raw
{instance}.silver.mobility.vehicle_positions_clean
{instance}.gold.mobility.fleet_kpis_daily
{instance}.gold.mobility.route_compliance_weekly
```

## ENTI Normative References
- ISO 37120 / 37122 / 37123 — Sustainable cities indicators
- ETSI EN 303 645 — IoT security
- FIWARE NGSI-LD (ETSI GS CIM 009) — reference only (see G3)
- OGC standards (WMS, WFS, SensorThings)
- INSPIRE Directive (spatial data)

## Procurement Context
- **CIRA**: Comunidade Intermunicipal da Região de Aveiro (12 municipalities + common)
- **AMP**: Área Metropolitana do Porto
- **TS**: Tâmega e Sousa
- **VDL**: Viseu Dão Lafões
- Typical verticals per procurement: mobility + environment + incidents
- PRR / Portugal 2030 funding requires auditability and ENTI compliance
