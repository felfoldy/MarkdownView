//
//  TextBuilder.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/4/13.
//

import SwiftUI

@resultBuilder
struct TextBuilder {
    static func buildBlock(_ components: Text...) -> Text {
        components.reduce(Text(verbatim: ""), joined)
    }

    static func buildArray(_ components: [Text]) -> Text {
        components.reduce(Text(verbatim: ""), joined)
    }

    // Interpolated, as `Text`'s `+` is deprecated.
    private static func joined(_ first: Text, _ second: Text) -> Text {
        Text("\(first)\(second)")
    }
    
    static func buildOptional(_ component: Text?) -> Text {
        if let component {
            return component
        }
        return Text(verbatim: "")
    }
    
    static func buildExpression(_ expression: Image) -> Text {
        Text(expression)
    }
    
    static func buildExpression(_ expression: Text) -> Text {
        expression
    }
    
    static func buildPartialBlock(accumulated: Text, next: Text) -> Text {
        joined(accumulated, next)
    }
    
    static func buildPartialBlock(first: Text) -> Text {
        first
    }
    
    static func buildEither(first component: Text) -> Text {
        component
    }
    
    static func buildEither(second component: Text) -> Text {
        component
    }
}
