import Cocoa

final class StatusBarController {

    private let item: NSStatusItem
    private let ping = PingService()
    private var settings: Settings
    private var settingsController: SettingsWindowController?

    private enum Tag: Int { case statusLine = 1 }

    private static let hasPromptedKey = "pd_hasPromptedLaunchAtLogin"

    init() {
        item     = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        settings = Settings.load()

        buildMenu()
        render(status: nil)

        promptLaunchAtLoginIfNeeded()

        ping.onStatusChanged = { [weak self] status in
            self?.render(status: status)
        }

        ping.start(host: settings.host, interval: settings.interval)
    }

    func stop() {
        ping.stop()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let statusItem = NSMenuItem()
        statusItem.tag       = Tag.statusLine.rawValue
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(
            NSMenuItem(
                title: "Quit Ping Dot",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        item.menu = menu
    }

    private func render(status: PingService.Status?) {
        updateIcon(status: status)
        updateStatusLine(status: status)
    }

    private func updateStatusLine(status: PingService.Status?) {
        guard let mi = item.menu?.item(withTag: Tag.statusLine.rawValue) else {
            return
        }

        switch status {
        case .ok:
            mi.title = "● \(settings.host)  —  reachable"

        case .nok:
            mi.title = "● \(settings.host)  —  unreachable"

        case nil:
            mi.title = "● \(settings.host)  —  checking…"
        }
    }

    private func updateIcon(status: PingService.Status?) {
        guard let button = item.button else { return }

        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .fade
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        button.layer?.add(transition, forKey: kCATransition)

        button.image = makeIcon(status: status)

        button.setAccessibilityLabel(
            "Ping Dot — \(status.map { $0 == .ok ? "OK" : "NOK" } ?? "checking")"
        )
    }

    private func makeIcon(status: PingService.Status?) -> NSImage {
        let canvas: CGFloat = 18
        let d: CGFloat = 12
        let o = (canvas - d) / 2
        let nokColor = settings.nokColor

        let image = NSImage(
            size: NSSize(width: canvas, height: canvas),
            flipped: false
        ) { _ in

            let path = NSBezierPath(
                ovalIn: NSRect(x: o, y: o, width: d, height: d)
            )

            switch status {

            case .ok:
                NSColor.white.setFill()
                path.fill()

                NSColor(white: 0.5, alpha: 0.35).setStroke()
                path.lineWidth = 0.5
                path.stroke()

            case .nok:
                nokColor.withAlphaComponent(0.85).setFill()
                path.fill()

            case nil:
                NSColor.white.withAlphaComponent(0.3).setFill()
                path.fill()
            }

            return true
        }

        image.isTemplate = false
        return image
    }

    @objc private func openSettings() {
        if let existing = settingsController,
           existing.window?.isVisible == true {

            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = SettingsWindowController(settings: settings)

        controller.onSave = { [weak self] newSettings in
            guard let self = self else { return }

            self.settings = newSettings
            newSettings.save()

            LaunchAtLoginManager.setEnabled(
                newSettings.launchAtLogin
            )

            self.ping.restart(
                host: newSettings.host,
                interval: newSettings.interval
            )

            self.render(status: self.ping.currentStatus)
        }

        settingsController = controller

        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func promptLaunchAtLoginIfNeeded() {
        let defaults = UserDefaults.standard

        guard !defaults.bool(forKey: Self.hasPromptedKey) else {
            return
        }

        defaults.set(true, forKey: Self.hasPromptedKey)

        let alert = NSAlert()
        alert.messageText = "Launch Ping Dot at login?"
        alert.informativeText = "You can change this anytime in Settings."

        alert.addButton(withTitle: "Launch at Login")
        alert.addButton(withTitle: "Not Now")

        let shouldEnable =
            alert.runModal() == .alertFirstButtonReturn

        LaunchAtLoginManager.setEnabled(shouldEnable)

        settings.launchAtLogin = shouldEnable
        settings.save()
    }
}
