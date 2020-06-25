//
//  ViewConvertible.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/27.
//

import SwiftUI

protocol ViewConvertible {
    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewInterceptor: ViewInterceptor) -> [ViewType]
}

extension ViewConvertible {
    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewInterceptor: ViewInterceptor) -> [ViewType] {
        return [.init(from: AnyView(Text(rawString)))]
    }
}

public enum ViewType {
    case text(Text)
    case any(AnyView)
    private static var newlineText: Text { Text("\n") }
    static var newline: ViewType { .text(Text("\n")) }

    var isNewLine: Bool {
        switch self {
        case .text(let t):
            if t == Self.newlineText {
                return true
            }
            return false
        case .any:
            return false
        }
    }

    public init<Content: View>(from view: Content) {
        if let text = view as? Text {
            self = Self.text(text)
            return
        }
        self = Self.any(AnyView(view))
    }

    func any() -> AnyView {
        switch self {
        case .text(let t):
            return AnyView(t)
        case .any(let a):
            return a
        }
    }
}

extension Array where Element == ViewType {

    func joinText() -> Self {
        return reduce(into: []) { (joined, v) in
            if let last = joined.last,
                case ViewType.text(let lt) = last,
                case ViewType.text(let t) = v {
                joined = joined.dropLast()
                joined.append(ViewType.text(lt + t))
                return
            }
            joined.append(v)
        }
    }

}
