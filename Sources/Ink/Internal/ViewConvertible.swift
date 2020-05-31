//
//  ViewConvertible.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/27.
//

import SwiftUI

protocol ViewConvertible {
    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewModifier: ViewModifier) -> AnyView
}

extension ViewConvertible {
    func view(usingURLs urls: NamedURLCollection, rawString: Substring, viewMaker: ViewMaker, viewModifier: ViewModifier) -> AnyView {
        return AnyView(Text(rawString))
    }
}
