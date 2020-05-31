/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/
import SwiftUI

internal struct Link: Fragment {
    var modifierTarget: Modifier.Target { .links }

    var target: Target
    var text: FormattedText

    static func read(using reader: inout Reader) throws -> Link {
        try reader.read("[")
        let text = FormattedText.read(using: &reader, terminators: ["]"])
        try reader.read("]")

        guard !reader.didReachEnd else { throw Reader.Error() }

        if reader.currentCharacter == "(" {
            reader.advanceIndex()
            let url = try reader.read(until: ")")
            return Link(target: .url(url), text: text)
        } else {
            try reader.read("[")
            let reference = try reader.read(until: "]")
            return Link(target: .reference(reference), text: text)
        }
    }

    func html(usingURLs urls: NamedURLCollection,
              modifiers: ModifierCollection) -> String {
        let url = target.url(from: urls)
        let title = text.html(usingURLs: urls, modifiers: modifiers)
        return "<a href=\"\(url)\">\(title)</a>"
    }

    func plainText() -> String {
        text.plainText()
    }

    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewModifier: ViewModifier) -> AnyView {
        let url = target.url(from: urls)
        let view = text.view(usingURLs: urls, rawString: rawString, viewMaker: viewMaker, viewModifier: viewModifier)
        return viewModifier.link((url: url, view: view))
    }
}

extension Link {
    enum Target {
        case url(URL)
        case reference(Substring)
    }
}

extension Link.Target {
    func url(from urls: NamedURLCollection) -> URL {
        switch self {
        case .url(let url):
            return url
        case .reference(let name):
            return urls.url(named: name) ?? name
        }
    }
}
