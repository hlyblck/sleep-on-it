import Foundation

struct ProductInfo {
    var title: String?
    var imageURL: URL?
    var price: Double?
}

/// Pulls title / image / price out of a product page's HTML.
/// Best effort: plenty of sites hide prices, so the price stays editable.
enum MetadataFetcher {
    static func fetch(_ url: URL) async -> ProductInfo {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            return ProductInfo()
        }
        let html = String(decoding: data, as: UTF8.self)
        let base = response.url ?? url
        let meta = metaTags(html)

        var info = ProductInfo()
        if let title = meta["og:title"] ?? meta["twitter:title"] ?? titleTag(html) {
            let cleaned = decodeEntities(title).trimmingCharacters(in: .whitespacesAndNewlines)
            info.title = cleaned.isEmpty ? nil : cleaned
        }
        if let image = meta["og:image:secure_url"] ?? meta["og:image"] ?? meta["twitter:image"] ?? meta["image"] {
            info.imageURL = URL(string: decodeEntities(image), relativeTo: base)?.absoluteURL
        }
        let priceText = meta["product:price:amount"] ?? meta["og:price:amount"] ?? meta["price"]
            ?? meta["twitter:data1"] ?? jsonLDPrice(html)
        info.price = priceText.flatMap(parsePrice)
        return info
    }

    // MARK: - Parsing helpers

    /// Collects <meta property|name|itemprop="…" content="…"> pairs (first one wins).
    private static func metaTags(_ html: String) -> [String: String] {
        var result: [String: String] = [:]
        guard let tagRegex = try? NSRegularExpression(pattern: "<meta\\s[^>]*>", options: [.caseInsensitive]),
              let attrRegex = try? NSRegularExpression(pattern: "([a-zA-Z:_-]+)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')")
        else { return result }

        let ns = html as NSString
        for match in tagRegex.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: match.range)
            let tagNS = tag as NSString
            var attrs: [String: String] = [:]
            for attr in attrRegex.matches(in: tag, range: NSRange(location: 0, length: tagNS.length)) {
                let key = tagNS.substring(with: attr.range(at: 1)).lowercased()
                let valueRange = attr.range(at: 2).location != NSNotFound ? attr.range(at: 2) : attr.range(at: 3)
                guard valueRange.location != NSNotFound else { continue }
                attrs[key] = tagNS.substring(with: valueRange)
            }
            guard let content = attrs["content"], !content.isEmpty else { continue }
            for key in ["property", "name", "itemprop"] {
                if let name = attrs[key]?.lowercased(), result[name] == nil {
                    result[name] = content
                }
            }
        }
        return result
    }

    private static func titleTag(_ html: String) -> String? {
        firstCapture("<title[^>]*>([^<]+)</title>", in: html)
    }

    /// Structured product data many shops embed: "price": "129.99"
    private static func jsonLDPrice(_ html: String) -> String? {
        firstCapture("\"(?:price|lowPrice)\"\\s*:\\s*\"?([0-9][0-9.,]*)", in: html)
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }

    /// "$1,299.00" → 1299.0, "89,95 €" → 89.95
    static func parsePrice(_ raw: String) -> Double? {
        var text = raw.filter { "0123456789.,".contains($0) }
        if text.contains(".") {
            text.removeAll { $0 == "," }
        } else if let comma = text.lastIndex(of: ","), text.distance(from: comma, to: text.endIndex) == 3 {
            text.replaceSubrange(comma...comma, with: ".")
            text.removeAll { $0 == "," }
        } else {
            text.removeAll { $0 == "," }
        }
        guard let value = Double(text), value > 0 else { return nil }
        return value
    }

    private static func decodeEntities(_ text: String) -> String {
        var result = text
        let entities = ["&amp;": "&", "&quot;": "\"", "&#39;": "'", "&#x27;": "'", "&apos;": "'",
                        "&lt;": "<", "&gt;": ">", "&nbsp;": " ", "&#x2F;": "/", "&#47;": "/"]
        for (entity, value) in entities {
            result = result.replacingOccurrences(of: entity, with: value)
        }
        return result
    }
}
