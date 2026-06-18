import Foundation

nonisolated enum LaunchAtLoginManager {

    private static let label = (Bundle.main.bundleIdentifier ?? "nathhdt.ping-dot") + ".launcher"
    private static let queue = DispatchQueue(label: "io.pingdot.launchatlogin", qos: .utility)

    private static var agentURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: agentURL.path)
    }

    static func setEnabled(_ enabled: Bool) {
        queue.async {
            enabled ? install() : uninstall()
        }
    }

    private static func install() {
        guard let executablePath = Bundle.main.executablePath else { return }

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true
        ]

        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0
        ) else { return }

        try? FileManager.default.createDirectory(
            at: agentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: agentURL, options: .atomic)

        runLaunchctl(["load", agentURL.path])
    }

    private static func uninstall() {
        runLaunchctl(["unload", agentURL.path])
        try? FileManager.default.removeItem(at: agentURL)
    }

    private static func runLaunchctl(_ arguments: [String]) {
        let task = Process()
        task.executableURL  = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments      = arguments
        task.standardOutput = FileHandle.nullDevice
        task.standardError  = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
    }
}
