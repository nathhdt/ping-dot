import Cocoa

final class SettingsWindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate {

    var onSave: ((Settings) -> Void)?

    private let hostField     = NSTextField()
    private let intervalField = NSTextField()
    private let colorWell     = NSColorWell()

    init(settings: Settings) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 152),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self

        populate(with: settings)
        buildLayout()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func populate(with s: Settings) {
        hostField.stringValue        = s.host
        hostField.placeholderString  = "hostname or IP"

        intervalField.stringValue       = String(format: "%.0f", s.interval)
        intervalField.placeholderString = "5"
        intervalField.delegate          = self

        colorWell.color      = s.nokColor
        colorWell.isBordered = true
    }

    private func buildLayout() {
        guard let cv = window?.contentView else { return }

        let rows = NSStackView(views: [
            fieldRow(label: "Host/IP",      field: hostField),
            fieldRow(label: "Interval (s)", field: intervalField),
            colorRow()
        ])
        rows.orientation = .vertical
        rows.alignment   = .leading
        rows.spacing     = 10

        let root = NSStackView(views: [rows, buttonBar()])
        root.orientation  = .vertical
        root.alignment    = .trailing
        root.spacing      = 14
        root.translatesAutoresizingMaskIntoConstraints = false

        cv.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: cv.topAnchor, constant: 20),
            root.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -20),
            root.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -20)
        ])
    }

    private func fieldRow(label text: String, field: NSTextField) -> NSStackView {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: 160).isActive = true

        let s = NSStackView(views: [label(text), field])
        s.orientation = .horizontal
        s.spacing     = 8
        s.alignment   = .centerY
        return s
    }

    private func colorRow() -> NSStackView {
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.widthAnchor.constraint(equalToConstant: 44).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let s = NSStackView(views: [label("Unreachable color"), colorWell])
        s.orientation = .horizontal
        s.spacing     = 8
        s.alignment   = .centerY
        return s
    }

    private func buttonBar() -> NSStackView {
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(didCancel))
        cancel.keyEquivalent = "\u{1b}"

        let save = NSButton(title: "Save", target: self, action: #selector(didSave))
        save.keyEquivalent = "\r"
        save.bezelStyle    = .rounded

        let s = NSStackView(views: [cancel, save])
        s.orientation = .horizontal
        s.spacing     = 8
        return s
    }

    private func label(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text + ":")
        l.alignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        l.widthAnchor.constraint(equalToConstant: 115).isActive = true
        return l
    }

    @objc private func didSave() {
        let host = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty else {
            return alert("Host cannot be empty.")
        }
        guard HostValidator.isValid(host) else {
            return alert("Enter a valid IPv4 address, IPv6 address, or hostname.")
        }
        guard let iv = Int(intervalField.stringValue), (1...3600).contains(iv) else {
            return alert("Interval must be a whole number between 1 and 3600 seconds.")
        }
        onSave?(Settings(host: host, interval: TimeInterval(iv), nokColor: colorWell.color))
        close()
    }

    @objc private func didCancel() { close() }

    private func alert(_ message: String) {
        guard let w = window else { return }
        let a = NSAlert()
        a.messageText     = "Invalid input"
        a.informativeText = message
        a.alertStyle      = .warning
        a.beginSheetModal(for: w)
    }
    
    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField, field === intervalField else { return }
        let digitsOnly = field.stringValue.filter(\.isNumber)
        if digitsOnly != field.stringValue {
            field.stringValue = digitsOnly
        }
    }

    func windowWillClose(_ notification: Notification) {
        colorWell.deactivate()
    }
}
