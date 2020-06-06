//
//  ViewConvertible.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/27.
//

import SwiftUI

protocol ViewConvertible {
    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewModifier: ViewModifier) -> [ViewType]
}

extension ViewConvertible {
    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewModifier: ViewModifier) -> [ViewType] {
        return [.text(Text(rawString))]
    }
}

enum ViewType {
    case text(Text)
    case any(AnyView)

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
