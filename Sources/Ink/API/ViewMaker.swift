//
//  File.swift
//  
//
//  Created by Makoto Aoyama on 2020/05/30.
//

import Foundation
import SwiftUI

public struct ViewMaker {
    var image: (URL) -> AnyView

    public init(image: @escaping (Substring) -> AnyView) {
        self.image = image
    }
}
