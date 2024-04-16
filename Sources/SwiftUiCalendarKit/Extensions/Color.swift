//
//  File.swift
//  
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI

extension Color {

    public init?(hex: String) {

        let red, green, blue, alpha: CGFloat

        let hexWithAlpha = hex + "ff"

        if hexWithAlpha.hasPrefix("#") {
            let start = hexWithAlpha.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hexWithAlpha[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    red = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    alpha = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: red, green: green, blue: blue, opacity: alpha)
                    return
                }
            }
        }

        return nil
    }
}
