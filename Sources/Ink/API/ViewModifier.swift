//
//  File.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/31.
//

import Foundation
import SwiftUI

public struct ViewModifier {
    var link: ((url: Substring, view: AnyView)) -> AnyView

    public init(link: @escaping ((url: Substring, view: AnyView)) -> AnyView) {
        self.link = link
    }
}
