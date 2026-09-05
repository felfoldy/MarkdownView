//
//  SVGView.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/10/21.
//

import SwiftUI

#if canImport(WebKit)
struct SVGView: View {
    var svg: SVG
    
    @State private var actualSize = CGSize.zero
    @State private var viewWidth = CGFloat.zero
   
    var body: some View {
        HTMLView(svg.htmlRepresentation) { _ in
            
        } onFinishLoading: { webView in
            webView.evaluateJavaScript("document.querySelector('svg').getBoundingClientRect().height") { result, _ in
                if let height = (result as? NSNumber)?.doubleValue, height.isNormal {
                    actualSize.height = height
                }
            }
        }
        .disabled(disableInteractions)
        // Scale down to the available width, but never up past the SVG's own size.
        .frame(maxWidth: svg.naturalSize?.width ?? .infinity)
        .frame(height: actualSize.height)
        .widthOfView($viewWidth)

    }

    private var disableInteractions: Bool {
        true
    }
}
#endif

// MARK: - SVG Helpers

struct SVG: Identifiable, Hashable {
    
    var id = UUID()
    var htmlRepresentation: String
    /// The size the SVG declares for itself, used as an upper bound so a small
    /// graphic such as a badge is not blown up to fill its container.
    var naturalSize: CGSize?

    init?(from string: String) {
        let string = string.removeCommentsAndXMLDescription()
        if string.starts(with: "<svg") {
            let scaled = string.scalingRootSVGToWidth()
            self.init(html: scaled.markup)
            self.naturalSize = scaled.naturalSize
        } else {
            return nil
        }
    }

    private init(html: String) {
        // Remove test cases to enable WKWebview to render SVG content.
        var representation = "<html><head><meta name=viewport content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'></head><body style='margin:0;padding:0;background-color:transparent;'><div id='svg_content' style=''>\(html)</div></body></html>"
        let testCases = representation.getElementsByTagName("d:SVGTestCase")
        for testCase in testCases {
            representation = representation.replacingOccurrences(of: testCase, with: "")
        }
        self.htmlRepresentation = representation
    }
}

fileprivate extension String {
    /// Give the root `<svg>` a viewBox and drop its fixed width and height, so it
    /// scales to the width it is given instead of laying out at its own.
    ///
    /// An SVG only scales when a viewBox establishes its coordinate system. Charts
    /// such as star-history's ship `width="800"` with no viewBox, so in a narrower
    /// column only a slice of the drawing is visible.
    func scalingRootSVGToWidth() -> (markup: String, naturalSize: CGSize?) {
        guard let openingTagEnd = range(of: ">")?.upperBound else { return (self, nil) }

        var openingTag = String(self[startIndex..<openingTagEnd])
        let remainder = String(self[openingTagEnd...])

        func attribute(_ name: String) -> String? {
            guard let regex = try? NSRegularExpression(pattern: "\\s\(name)\\s*=\\s*[\"']([^\"']*)[\"']", options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: openingTag, range: NSRange(openingTag.startIndex..., in: openingTag)),
                  let range = Range(match.range(at: 1), in: openingTag) else { return nil }
            return String(openingTag[range])
        }

        func removeAttribute(_ name: String) {
            guard let regex = try? NSRegularExpression(pattern: "\\s\(name)\\s*=\\s*[\"'][^\"']*[\"']", options: [.caseInsensitive]) else { return }
            openingTag = regex.stringByReplacingMatches(
                in: openingTag,
                range: NSRange(openingTag.startIndex..., in: openingTag),
                withTemplate: ""
            )
        }

        let existingViewBox = attribute("viewBox")
        let width = attribute("width")?.htmlSize()
        let height = attribute("height")?.htmlSize()

        let naturalSize: CGSize
        if let width, let height, width > 0, height > 0 {
            naturalSize = CGSize(width: width, height: height)
        } else if let viewBox = existingViewBox?.viewBoxSize() {
            naturalSize = viewBox
        } else {
            // Nothing declares a size, so there is no coordinate system to scale
            // within and no upper bound to respect.
            return (self, nil)
        }

        if existingViewBox == nil {
            guard let rootRange = openingTag.range(of: "<svg", options: [.caseInsensitive]) else {
                return (self, nil)
            }
            openingTag.replaceSubrange(
                rootRange,
                with: "<svg viewBox=\"0 0 \(naturalSize.width) \(naturalSize.height)\""
            )
        }

        removeAttribute("width")
        removeAttribute("height")

        return (openingTag + remainder, naturalSize)
    }

    /// The width and height of a `viewBox` attribute value.
    func viewBoxSize() -> CGSize? {
        let numbers = split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }

        guard numbers.count == 4, numbers[2] > 0, numbers[3] > 0 else { return nil }

        return CGSize(width: numbers[2], height: numbers[3])
    }

    /// Get the specific tag from raw HTML.
    /// - Parameter tag: The string of the tag's name.
    /// - Returns: A set of DOMs, contains all raw HTMLs of the tag.
    func getElementsByTagName(_ tag: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "<\(tag)[\\s\\S]+?/\(tag)>", options: NSRegularExpression.Options.allowCommentsAndWhitespace) else { return [] }
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
        
        var DOMs = [String]()
        for match in matches {
            guard let range = Range(match.range, in: self) else { continue }
            DOMs.append(String(self[range]))
        }
        
        return DOMs
    }
    
    /// Extract size values from the output of the script.
    /// - Returns: A size value for width or height transformed from the CSS.
    func htmlSize() -> Double? {
        Double(
            self
                .replacingOccurrences(of: "px", with: "")
                .replacingOccurrences(of: "em", with: "")
                .replacingOccurrences(of: "pt", with: "")
        )
    }
    
    /// Remove comments and the XML description from the raw HTML to improve SVG detection.
    /// - Returns: A string without HTML comments and the XML description.
    func removeCommentsAndXMLDescription() -> String {
        guard let regex = try? NSRegularExpression(pattern: "<![\\s\\S]+?>[\\s]*", options: []) else { return self }
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
        
        var result = self
        for match in matches {
            guard let range = Range(match.range, in: self) else { continue }
            result = result.replacingOccurrences(of: self[range], with: "")
        }
        
        if let regex = try? NSRegularExpression(pattern: "<[?]{1}[\\s\\S]*?[?]{1}>[\\s]*", options: []) {
            let matches = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
            
            for match in matches {
                guard let range = Range(match.range, in: self) else { continue }
                result = result.replacingOccurrences(of: self[range], with: "")
            }
        }
        
        return result
    }
}
