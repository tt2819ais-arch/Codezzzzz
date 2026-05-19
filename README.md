# NetPulse iOS

SwiftUI iOS app with two tabs:
- Internet diagnostics (IP, Geo, ping, speed test simulation, anomaly detection, VPN deeplink)
- Apple Health statistics (steps by day/week/month/all)

## Stack
- SwiftUI + MVVM
- async/await + Combine-free async pipelines
- Network framework + HealthKit + Charts

## Build in CI
GitHub Actions workflow builds Release archive and exports unsigned IPA artifact.
