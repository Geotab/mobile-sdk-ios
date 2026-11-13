import Foundation

enum WebViewAudioOriginPolicy {
    enum Decision {
        case allow, prompt, deny(String)
    }

    static func isAllowed(protocol scheme: String, host: String, port: Int, isMainFrame: Bool,
                          topLevelURL: URL?, configuredServer: String?) -> Bool {
        if case .allow = decision(protocol: scheme, host: host, port: port, isMainFrame: isMainFrame,
                                  topLevelURL: topLevelURL, configuredServer: configuredServer) { return true }
        return false
    }

    static func decision(protocol scheme: String, host: String, port: Int, isMainFrame: Bool,
                         topLevelURL: URL?, configuredServer: String?) -> Decision {
        guard isMainFrame else { return .deny("not main frame") }
        guard scheme.lowercased() == "https", topLevelURL?.scheme?.lowercased() == "https" else {
            return .deny("not https")
        }
        guard let request = Origin(host: host, port: port),
              let topLevel = httpsOrigin(topLevelURL), request == topLevel else { return .deny("origin mismatch") }

        if topLevel.host.range(of: #"\A(my|alpha|myalpha|preview|mypreview)[0-9]*\.geotab\.com\z"#,
                               options: .regularExpression) != nil
            || topLevel.host.range(of: #"\Amy[0-9]*\.geotab\.(ca|co\.za)\z"#, options: .regularExpression) != nil {
            return .allow
        }
        let address = (configuredServer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "/", omittingEmptySubsequences: false).first.map(String.init) ?? ""
        if topLevel == httpsOrigin(URL(string: "https://\(address)")) { return .allow }
        if ["geotab.com", "geotab.ca", "geotab.co.za"].contains(where: {
            topLevel.host == $0 || topLevel.host.hasSuffix(".\($0)")
        }) { return .prompt }
        return .deny("untrusted host")
    }

    private static func httpsOrigin(_ url: URL?) -> Origin? {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = url.host else { return nil }
        // Keep the ASCII/punycode host used by WebKit rather than URLComponents' decoded IDN.
        // URLComponents rejects nonnumeric ports; also reject an explicitly empty port.
        let authority = url.absoluteString.dropFirst("https://".count).prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        let port = components.port ?? 443
        guard !authority.hasSuffix(":"), (1...65535).contains(port) else { return nil }
        return Origin(host: host, port: port)
    }

    private struct Origin: Equatable {
        let host: String
        let port: Int

        init?(host: String, port: Int) {
            guard !host.isEmpty, !host.hasSuffix(".") else { return nil }
            let effectivePort = port == 0 || port == -1 ? 443 : port
            guard (1...65535).contains(effectivePort) else { return nil }
            self.host = host.lowercased()
            self.port = effectivePort
        }
    }
}
