//
//  File.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/31.
//

import Foundation
import SwiftUI

public struct ViewModifier {
    var textLink: ((url: Substring, text: Text)) -> Text
    var anyViewLink: ((url: Substring, anyView: AnyView)) -> AnyView

    public init(textLink: @escaping ((url: Substring, text: Text)) -> Text, anyViewLink: @escaping ((url: Substring, anyView: AnyView)) -> AnyView) {
        self.textLink = textLink
        self.anyViewLink = anyViewLink
    }
}
