//
//  MarkdownTapModifier.swift
//  MarkdownView
//

import SwiftUI
import Markdown
#if canImport(RichText)
import RichText
#endif

extension View {
    /// Reports the source range of the top-level block a `MarkdownText` was
    /// tapped in. Links and embedded views, such as block quotes and code
    /// blocks, keep their taps and report nothing.
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public func onMarkdownBlockTap(
        perform action: @escaping @MainActor (SourceRange) -> Void
    ) -> some View {
        #if canImport(RichText)
        onTextTap { text, index in
            if let range = MarkdownTapResolver.blockRange(in: text, at: index) {
                action(range)
            }
        }
        #else
        self
        #endif
    }
}

enum MarkdownTapResolver {
    /// The block holding the insertion point `index`, or the one it ends:
    /// the line break between two blocks belongs to neither.
    static func blockRange(
        in text: AttributedString,
        at index: AttributedString.Index
    ) -> SourceRange? {
        var ending: SourceRange?
        for (range, runs) in text.runs[\.markdownBlockRange] {
            guard let range else { continue }
            if runs.contains(index) { return range }
            if runs.upperBound == index { ending = range }
        }
        return ending
    }
}
