//
//  MarkdownViewAttributeScope.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/10/20.
//

import Foundation
import Markdown

extension AttributeScopes {
    struct MarkdownViewAttributeScope: AttributeScope {
        let isHTML: IsHTMLAttribute
        let markdownBlockRange: MarkdownBlockRangeAttribute
    }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.MarkdownViewAttributeScope, T>) -> T {
        return self[T.self]
    }
}

extension AttributeScopes.MarkdownViewAttributeScope {
    enum IsHTMLAttribute: AttributedStringKey {
        static let name: String = "isHTML"
        
        typealias Value = Bool
    }

    /// The source range of the top-level block a run belongs to.
    enum MarkdownBlockRangeAttribute: AttributedStringKey {
        static let name: String = "markdownBlockRange"

        typealias Value = SourceRange
    }
}
