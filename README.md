# NetPulse

An iOS app that does two things: checks how good your internet connection actually is, and shows your step history from HealthKit.

## What it measures

The connection test reports five numbers, and unlike most quick "speed test" toys, it tries to measure them honestly:

- **Latency (RTT)** — time to complete a raw TCP handshake to `1.1.1.1:443` via `Network.framework`. This is close to a true round-trip, not a full HTTPS request inflated by DNS and TLS setup.
- **Jitter** — average variation between consecutive latency samples. High jitter is what makes calls and games feel bad.
- **Packet loss** — share of handshake attempts that don't finish before the timeout. Real failures, not HTTP errors dressed up as loss.
- **Download / upload speed** — a warm-up transfer opens the TCP window first, then several samples are taken and the **median** is reported, so the result isn't dragged down by slow-start. Transfers go through `speed.cloudflare.com`.
- **Quality score (0–100)** — a weighted blend, leaning on latency and loss because that's what people feel most.

Results are graded (good / fair / poor) and saved locally so you can see trends over time. A run that trips two or more red signals (high latency, loss, jitter, or near-zero throughput) flags a possible restricted connection.

## Features

- Animated quality gauge and a metric grid with per-metric ratings
- Local history with a score-trend chart (last 100 runs, stored on device)
- "How we measure" sheet explaining every number
- Step statistics from HealthKit (day / week / month / all) with a bar chart and totals
- Settings: light/dark/system theme, number of latency samples, toggle the speed test, auto-run on launch, haptics, and a configurable VPN deep-link
- Share a plain-text report, pull-to-refresh, haptic feedback

## Architecture

SwiftUI, iOS 17+, MVVM.

```
NetPulse/
├── App/            App entry, theme injection
├── Models/         NetworkReport + derived ratings/score
├── Services/       Probes (latency, throughput), GeoIP, connection type,
│                   HealthKit, history persistence, settings, haptics
├── ViewModels/     Diagnostics + Health state
└── Views/
    ├── Components/  Reusable cards, tiles, gauge
    ├── Theme/       Design tokens (single muted accent, system materials)
    ├── Internet/    Diagnostics screen, history, methodology
    ├── Health/      Step statistics
    └── Settings/    Preferences
```

The measurement code is split into focused probes:
- `LatencyProbe` — TCP-handshake timing with timeout-based loss accounting
- `ThroughputProbe` — warm-up + median throughput
- `ConnectionMonitor` — current Wi-Fi / cellular / Ethernet type
- `NetworkDiagnosticsEngine` — orchestrates a run and reports progress (throughput runs after latency so they don't fight for bandwidth)

## Build

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`:

```bash
xcodegen generate
open NetPulse.xcodeproj
```

CI (`.github/workflows/ios-ipa.yml`) builds an unsigned `.ipa` on every push for sideloading.

## Privacy

Step data stays on the device — it's read from HealthKit and never leaves. The connection test contacts `ipinfo.io` (for IP, city, and ISP), `cloudflare.com` (speed), and `1.1.1.1` (latency). Diagnostics history is stored only in the app's local Application Support directory.
