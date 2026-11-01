import Foundation

enum AppConfig {
    static let waitOptions = [7, 14, 30]
    static let defaultWait = 14

    /// The shared folder that both the app and the Share Extension can read/write.
    /// We read the real group ID out of the signing profile so it keeps working even if
    /// a refresh app (AltStore / SideStore) re-signs the app with a different group name.
    static let appGroupID: String = {
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String ?? ""
        if let groups = provisionedAppGroups(), !groups.isEmpty {
            return groups.contains(fromPlist) ? fromPlist : groups[0]
        }
        return fromPlist
    }()

    private static func provisionedAppGroups() -> [String]? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .isoLatin1),
              let start = text.range(of: "<?xml"),
              let end = text.range(of: "</plist>"),
              start.lowerBound < end.upperBound,
              let plistData = String(text[start.lowerBound..<end.upperBound]).data(using: .isoLatin1),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any]
        else { return nil }
        return entitlements["com.apple.security.application-groups"] as? [String]
    }
}

extension Double {
    var asCurrency: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

enum URLExtract {
    /// Finds the first web link in a piece of text ("Check this out https://…").
    static func firstURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            for match in detector.matches(in: trimmed, range: range) {
                if let url = match.url, let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                    return url
                }
            }
        }
        if !trimmed.contains(" "), trimmed.contains("."), let url = URL(string: "https://" + trimmed) {
            return url
        }
        return nil
    }
}
