//
//  RemoteUILabel.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/25.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

extension UILabel {
    convenience init(_ c: ColorSet) {
        self.init()
        backgroundColor = c.primary
        tintColor = c.secondary
        layer.cornerRadius = 10
        layer.borderWidth = 0
        clipsToBounds = true    // we need this for corner radius to work.
        tintColor = .white
        textColor = .white
        textAlignment = .center
    }
}

typealias RemoteUILabel = UILabel
