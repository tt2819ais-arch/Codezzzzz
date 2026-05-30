import Foundation
import Network

/// Measures latency as the time to complete a TCP handshake to a host:port,
/// using `Network.framework` directly. This is far closer to a true round-trip
/// time than timing a full HTTPS request (which also pays for DNS, TLS, and
/// server processing).
///
/// A probe that does not become `.ready` within `timeout` is reported as a
/// loss, which feeds the packet-loss statistic honestly.
struct LatencyProbe {
    let host: String
    let port: UInt16
    var timeout: TimeInterval = 2.0

    /// Result of a batch of probes.
    struct Result {
        /// Successful RTT samples, in milliseconds.
        let samples: [Double]
        /// Number of attempts that timed out or failed.
        let failures: Int

        var attempts: Int { samples.count + failures }

        var averageMs: Double {
            guard !samples.isEmpty else { return 0 }
            return samples.reduce(0, +) / Double(samples.count)
        }

        /// Mean absolute difference between consecutive samples.
        var jitterMs: Double {
            guard samples.count > 1 else { return 0 }
            let diffs = zip(samples.dropFirst(), samples).map { abs($0 - $1) }
            return diffs.reduce(0, +) / Double(diffs.count)
        }

        var lossPercent: Double {
            guard attempts > 0 else { return 0 }
            return Double(failures) / Double(attempts) * 100
        }
    }

    /// Runs `count` sequential handshakes and aggregates the result.
    func run(count: Int) async -> Result {
        var samples: [Double] = []
        var failures = 0
        for _ in 0..<count {
            if let rtt = await singleHandshakeMs() {
                samples.append(rtt)
            } else {
                failures += 1
            }
            // Small spacing so we sample the link over time, not in one burst.
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
        return Result(samples: samples, failures: failures)
    }

    /// One handshake. Returns elapsed milliseconds, or nil on timeout/failure.
    private func singleHandshakeMs() async -> Double? {
        await withCheckedContinuation { continuation in
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                continuation.resume(returning: nil)
                return
            }
            let params = NWParameters.tcp
            let endpoint = NWEndpoint.hostPort(
                host: NWEndpoint.Host(host),
                port: nwPort
            )
            let connection = NWConnection(to: endpoint, using: params)
            let queue = DispatchQueue(label: "netpulse.latency")
            let start = DispatchTime.now()

            // Guard against multiple resumes from racing handlers/timeout.
            let lock = NSLock()
            var finished = false
            func finish(_ value: Double?) {
                lock.lock(); defer { lock.unlock() }
                guard !finished else { return }
                finished = true
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                    finish(elapsed)
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }

            queue.asyncAfter(deadline: .now() + timeout) { finish(nil) }
            connection.start(queue: queue)
        }
    }
}
