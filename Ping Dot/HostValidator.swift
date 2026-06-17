import Foundation

enum HostValidator {

    static func isValid(_ host: String) -> Bool {
        isValidIPv4(host) || isValidIPv6(host) || isValidHostname(host)
    }

    private static func isValidIPv4(_ host: String) -> Bool {
        var addr = in_addr()
        return host.withCString { inet_pton(AF_INET, $0, &addr) == 1 }
    }

    private static func isValidIPv6(_ host: String) -> Bool {
        var addr = in6_addr()
        return host.withCString { inet_pton(AF_INET6, $0, &addr) == 1 }
    }

    private static func isValidHostname(_ host: String) -> Bool {
        guard !host.isEmpty, host.count <= 253 else { return false }

        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard !labels.isEmpty else { return false }

        return labels.allSatisfy { label in
            isValidLabel(label)
        }
    }

    private static func isValidLabel(_ label: Substring) -> Bool {
        guard (1...63).contains(label.count) else { return false }
        guard let first = label.first, let last = label.last else { return false }
        guard first != "-", last != "-" else { return false }

        return label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
    }
}
