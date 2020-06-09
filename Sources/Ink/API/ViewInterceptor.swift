//
//  File.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/31.
//

import Foundation
import SwiftUI

public struct ViewInterceptor {
    var link: ((url: Substring, text: ViewType)) -> ViewType

    public init(link: @escaping ((url: Substring, text: ViewType)) -> ViewType) {
        self.link = link
    }
}
