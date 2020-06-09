/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import SwiftUI

///
/// A parser used to convert Markdown text into HTML.
///
/// You can use an instance of this type to either convert
/// a Markdown string into an HTML string, or into a `Markdown`
/// value, which also contains any metadata values found in
/// the parsed Markdown text.
///
/// To customize how this parser performs its work, attach
/// a `Modifier` using the `addModifier` method.
public struct MarkdownParser {
    private var modifiers: ModifierCollection
    private var viewMaker: ViewMaker
    private var viewInterceptor: ViewInterceptor!
    /// Initialize an instance, optionally passing an array
    /// of modifiers used to customize the parsing process.
    public init(modifiers: [Modifier] = []) {
        self.modifiers = ModifierCollection(modifiers: modifiers)
        self.viewMaker = ViewMaker(image: { (url) -> AnyView in
            AnyView(Text(url))
        })
    }

    public init(viewMaker: ViewMaker, viewInterceptor: ViewInterceptor) {
        self.modifiers = ModifierCollection(modifiers: [])
        self.viewMaker = viewMaker
        self.viewInterceptor = viewInterceptor
    }

    /// Add a modifier to this parser, which can be used to
    /// customize the parsing process. See `Modifier` for more info.
    public mutating func addModifier(_ modifier: Modifier) {
        modifiers.insert(modifier)
    }

    /// Convert a Markdown string into HTML, discarding any metadata
    /// found in the process. To preserve the Markdown's metadata,
    /// use the `parse` method instead.
    public func html(from markdown: String) -> String {
        parse(markdown).html
    }

    public func view(from markdown: String) -> some View {
        var reader = Reader(string: markdown)
        var fragments = [ParsedFragment]()
        var urlsByName = [String : URL]()
        var titleHeading: Heading?
        var metadata: Metadata?

        while !reader.didReachEnd {
            reader.discardWhitespacesAndNewlines()
            guard !reader.didReachEnd else { break }

            do {
                if metadata == nil, fragments.isEmpty, reader.currentCharacter == "-" {
                    if let parsedMetadata = try? Metadata.readOrRewind(using: &reader) {
                        metadata = parsedMetadata.applyingModifiers(modifiers)
                        continue
                    }
                }

                guard reader.currentCharacter != "[" else {
                    let declaration = try URLDeclaration.readOrRewind(using: &reader)
                    urlsByName[declaration.name] = declaration.url
                    continue
                }

                let type = fragmentType(for: reader.currentCharacter,
                                        nextCharacter: reader.nextCharacter)

                let fragment = try makeFragment(using: type.readOrRewind, reader: &reader)
                fragments.append(fragment)

                if titleHeading == nil, let heading = fragment.fragment as? Heading {
                    if heading.level == 1 {
                        titleHeading = heading
                    }
                }
            } catch {
                let paragraph = makeFragment(using: Paragraph.read, reader: &reader)
                fragments.append(paragraph)
            }
        }

        let urls = NamedURLCollection(urlsByName: urlsByName)

        let fragmentViews: [ViewType] = Array(fragments.map { (parsed) -> [ViewType] in
            return parsed.fragment.view(usingURLs: urls, rawString: parsed.rawString, viewMaker: viewMaker, viewInterceptor: viewInterceptor)
            }.joined()).joinText()

        let fragmentViewsWithID: [(id: UUID, view: ViewType)] = fragmentViews.map { (view) -> (id: UUID, view: ViewType) in
            let id = UUID()
            return (id: id, view: view)
        }

        return VStack(alignment: .leading) {
            ForEach(fragmentViewsWithID, id: \.id) { fragment in
                fragment.view.any()
            }
        }
    }


    /// Parse a Markdown string into a `Markdown` value, which contains
    /// both the HTML representation of the given string, and also any
    /// metadata values found within it.
    public func parse(_ markdown: String) -> Markdown {
        var reader = Reader(string: markdown)
        var fragments = [ParsedFragment]()
        var urlsByName = [String : URL]()
        var titleHeading: Heading?
        var metadata: Metadata?

        while !reader.didReachEnd {
            reader.discardWhitespacesAndNewlines()
            guard !reader.didReachEnd else { break }

            do {
                if metadata == nil, fragments.isEmpty, reader.currentCharacter == "-" {
                    if let parsedMetadata = try? Metadata.readOrRewind(using: &reader) {
                        metadata = parsedMetadata.applyingModifiers(modifiers)
                        continue
                    }
                }

                guard reader.currentCharacter != "[" else {
                    let declaration = try URLDeclaration.readOrRewind(using: &reader)
                    urlsByName[declaration.name] = declaration.url
                    continue
                }

                let type = fragmentType(for: reader.currentCharacter,
                                        nextCharacter: reader.nextCharacter)

                let fragment = try makeFragment(using: type.readOrRewind, reader: &reader)
                fragments.append(fragment)

                if titleHeading == nil, let heading = fragment.fragment as? Heading {
                    if heading.level == 1 {
                        titleHeading = heading
                    }
                }
            } catch {
                let paragraph = makeFragment(using: Paragraph.read, reader: &reader)
                fragments.append(paragraph)
            }
        }

        let urls = NamedURLCollection(urlsByName: urlsByName)

        let html = fragments.reduce(into: "") { result, wrapper in
            let html = wrapper.fragment.html(
                usingURLs: urls,
                rawString: wrapper.rawString,
                applyingModifiers: modifiers
            )

            result.append(html)
        }

        return Markdown(
            html: html,
            titleHeading: titleHeading,
            metadata: metadata?.values ?? [:]
        )
    }
}

private extension MarkdownParser {
    struct ParsedFragment {
        var fragment: Fragment
        var rawString: Substring
    }

    func makeFragment(using closure: (inout Reader) throws -> Fragment,
                      reader: inout Reader) rethrows -> ParsedFragment {
        let startIndex = reader.currentIndex
        let fragment = try closure(&reader)
        let rawString = reader.characters(in: startIndex..<reader.currentIndex)
        return ParsedFragment(fragment: fragment, rawString: rawString)
    }

    func fragmentType(for character: Character,
                      nextCharacter: Character?) -> Fragment.Type {
        switch character {
        case "#": return Heading.self
        case "!": return Image.self
        case "<": return HTML.self
        case ">": return Blockquote.self
        case "`": return CodeBlock.self
        case "-" where character == nextCharacter,
             "*" where character == nextCharacter:
            return HorizontalLine.self
        case "-", "*", "+", \.isNumber: return List.self
        case "|": return Table.self
        default: return Paragraph.self
        }
    }
}
