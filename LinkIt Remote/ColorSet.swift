//
//  ColorSet.swift
//  LinkIt Remote Color Set
//  Constants and structs for brand color
//
//  Created by Pablo Sun on 2017/8/25.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

struct ColorSet {
    var primary : UIColor
    var secondary : UIColor
}

class BrandColor {
    static let gold = ColorSet(primary: UIColor(rgb: 0xF39A1E), secondary: UIColor(rgb: 0xDEC9A5))
    static let yellow = ColorSet(primary: UIColor(rgb: 0xFED100), secondary: UIColor(rgb: 0xE1D4A0))
    static let blue = ColorSet(primary: UIColor(rgb: 0x00A1DE), secondary: UIColor(rgb: 0xABCBDD))
    static let green = ColorSet(primary: UIColor(rgb: 0x69BE28), secondary: UIColor(rgb: 0xB6CEA9))
    static let pink = ColorSet(primary: UIColor(rgb: 0xD71F85), secondary: UIColor(rgb: 0xDCAEC9))
    static let grey = ColorSet(primary: UIColor(rgb: 0x353630), secondary: UIColor(rgb: 0x5D5F54))
}

