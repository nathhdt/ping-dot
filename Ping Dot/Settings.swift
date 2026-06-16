import AppKit
import Foundation

struct Settings {

    var host:     String
    var interval: TimeInterval // seconds
    var nokColor: NSColor

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
        let iv = d.double(forKey: Key.interval)
        return Settings(
            host:     d.string(forKey: Key.host) ?? defaultHost,
            interval: iv >= 1 ? iv : defaultInterval,
            nokColor: storedColor() ?? defaultNokColor
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

    private static func storedColor() -> NSColor? {
        guard
            let data  = UserDefaults.standard.data(forKey: Key.nokColor),
            let color = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self, from: data)
        else { return nil }
        return color
    }
}
