//
//  MarkdownTapResolverTests.swift
//  MarkdownView
//

#if canImport(RichText)

import Markdown
import RichText
import SwiftUI
import Testing

@testable import MarkdownView

@MainActor
struct MarkdownTapResolverTests {
    private let markdown = """
    # Title

    First paragraph

    - one
    - two

    Last
    """

    /// The text as a `TextView` hands it to a tap, after RichText's own
    /// conversion, which is where a foreign attribute could be lost.
    private func rendered() -> AttributedString {
        MarkdownViewTestSupport
            .makeTextContent(markdown: markdown)
            .attributedString(environmentValues: EnvironmentValues())
    }

    /// The lines of the block a tap just after `marker` lands in.
    private func lines(after marker: String) -> ClosedRange<Int>? {
        let text = rendered()
        let string = String(text.characters)
        guard let range = string.range(of: marker) else { return nil }
        let index = text.characters.index(text.startIndex, offsetBy: string[..<range.upperBound].count)
        return MarkdownTapResolver.blockRange(in: text, at: index)
            .map { $0.lowerBound.line...$0.upperBound.line }
    }

    @Test func aTapInAParagraphNamesIt() {
        #expect(lines(after: "First par") == 3...3)
    }

    @Test func aTapAtTheEndOfALineNamesItsBlock() {
        #expect(lines(after: "Title") == 1...1)
        #expect(lines(after: "Last") == 8...8)
    }

    @Test func aTapAnywhereInAListNamesTheWholeList() {
        // The list's range ends where the next line starts.
        let lines = lines(after: "tw")
        #expect(lines?.lowerBound == 5)
        #expect(lines?.contains(6) == true)
    }
}

#endif
