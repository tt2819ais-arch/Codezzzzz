import Foundation
import Network

/// One-shot lookup of the current active connection type via `NWPathMonitor`.
enum ConnectionMonitor {
    static func currentType() async -> NetworkReport.ConnectionType {
        await withCheckedContinuation { (continuation: CheckedContinuation<NetworkReport.ConnectionType, Never>) in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "netpulse.path")
            let lock = NSLock()
            var resumed = false

            func finish(_ type: NetworkReport.ConnectionType) {
                lock.lock(); defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                monitor.cancel()
                continuation.resume(returning: type)
            }

            monitor.pathUpdateHandler = { path in
                let type: NetworkReport.ConnectionType
                if path.usesInterfaceType(.wifi) { type = .wifi }
                else if path.usesInterfaceType(.cellular) { type = .cellular }
                else if path.usesInterfaceType(.wiredEthernet) { type = .ethernet }
                else if path.status == .satisfied { type = .other }
                else { type = .unknown }
                finish(type)
            }
            monitor.start(queue: queue)

            // Safety net: if the path never updates, resolve as unknown.
            queue.asyncAfter(deadline: .now() + 3) { finish(.unknown) }
        }
    }
}
