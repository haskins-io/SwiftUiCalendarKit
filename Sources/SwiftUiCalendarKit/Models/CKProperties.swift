//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 30/12/2025.
//

import SwiftUI

public struct CKProperties {
    public var headingAligment: HorizontalAlignment = .leading
    
    public init(headingAligment: HorizontalAlignment = .leading) {
        self.headingAligment = headingAligment
    }
}
