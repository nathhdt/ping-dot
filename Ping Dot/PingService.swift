import Foundation

final class PingService {

    enum Status: Equatable { case ok, nok }

    var onStatusChanged: ((Status) -> Void)?
    private(set) var currentStatus: Status?

    private var timer:    Timer?
    private var host:     String = ""
    private var inFlight: Bool   = false
    private let queue = DispatchQueue(label: "io.pingdot.ping", qos: .utility)

    func start(host: String, interval: TimeInterval) {
        self.host = host
        arm(interval: interval)
        dispatchPing()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart(host: String, interval: TimeInterval) {
        stop()
        currentStatus = nil
        start(host: host, interval: interval)
    }

    private func arm(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.dispatchPing()
        }
    }

    private func dispatchPing() {
        guard !inFlight else { return }
        inFlight = true

        let target = host
        queue.async { [weak self] in
            let reachable = Self.runPing(host: target)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.inFlight = false
                let status: Status = reachable ? .ok : .nok
                guard status != self.currentStatus else { return }
                self.currentStatus = status
                self.onStatusChanged?(status)
            }
        }
    }

    private static func runPing(host: String) -> Bool {
        let task = Process()
        task.executableURL  = URL(fileURLWithPath: "/sbin/ping")
        task.arguments      = ["-c", "1", "-t", "2", host]
        task.standardOutput = FileHandle.nullDevice
        task.standardError  = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
}
