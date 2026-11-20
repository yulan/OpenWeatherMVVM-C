# 0006. Canonical metric units, converted in presentation

- **Status:** Accepted
- **Date:** 2026-11-20

## Context

The app requested `units=metric` and displayed °C and m/s to everyone. A US user expects °F, mph, miles and inHg; a UK user expects °C but mph and miles; a French user expects km/h.

## Decision

- The Data layer always requests metric. Domain values have one canonical unit each (°C, m/s, m, hPa), as documented on `Weather`.
- `WeatherDisplayModel` converts with `Measurement` for the injected `Locale`:
  - temperature: `UnitTemperature(forLocale:usage: .weather)`, rounded half-up and shown as "19°";
  - wind: `usage: .wind`;
  - visibility: `usage: .road`, two significant digits;
  - pressure: `UnitPressure(forLocale:usage: .barometric)`, two decimals for inHg.

## Alternatives considered

- **Ask the API for `units=imperial`:** the cache, the Domain and every test would then carry two unit systems, and a UK user still needs a mix of both.
- **A units setting in the app:** more UI to build and test. Following the system locale matches what users already chose; a setting can still be added on top.

## Consequences

- One code path, tested per locale in `WeatherDisplayModelTests` (en_US, en_GB, fr_FR).
- Tests compare text with spaces normalized: French uses narrow no-break spaces ("11 km/h"), and the exact character depends on the OS's ICU version.
- Weather saved by the offline cache stays valid if the user changes region.
