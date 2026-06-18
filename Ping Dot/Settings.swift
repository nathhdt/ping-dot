import AppKit
import Foundation

struct Settings {

    var host:     String
    var interval: TimeInterval // seconds
    var nokColor: NSColor
    var launchAtLogin: Bool

    static let defaultHost:     String       = "9.9.9.9"
    static let defaultInterval: TimeInterval = 5
    static let defaultNokColor: NSColor = NSColor(
        red: 0xe8 / 255.0,
        green: 0x6b / 255.0,
        blue: 0x77 / 255.0,
        alpha: 1.0
    )

    private enum Key {
        static let host     = "pd_host"
        static let interval = "pd_interval"
        static let nokColor = "pd_nokColor"
    }

    static func load() -> Settings {
        let d = UserDefaults.standard
        return Settings(
            host:          validatedHost(d.string(forKey: Key.host)),
            interval:      clampedInterval(d.double(forKey: Key.interval)),
            nokColor:      storedColor() ?? defaultNokColor,
            launchAtLogin: LaunchAtLoginManager.isEnabled
        )
    }

    func save() {
        let d = UserDefaults.standard
        d.set(host,     forKey: Key.host)
        d.set(interval, forKey: Key.interval)
        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: nokColor, requiringSecureCoding: false
        ) {
            d.set(data, forKey: Key.nokColor)
        }
    }

    private static func validatedHost(_ stored: String?) -> String {
        guard let stored, HostValidator.isValid(stored) else { return defaultHost }
        return stored
    }

    private static func clampedInterval(_ stored: TimeInterval) -> TimeInterval {
        guard stored >= 1 else { return defaultInterval }
        return min(stored, 3600)
    }

    private static func storedColor() -> NSColor? {
        guard
            let data  = UserDefaults.standard.data(forKey: Key.nokColor),
            let color = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self, from: data)
        else { return nil }
        return color
    }
}
