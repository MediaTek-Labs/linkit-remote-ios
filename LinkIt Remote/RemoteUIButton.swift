//
//  RemoteUIButton.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/25.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

class RemoteUIButton : UIButton {
    var colorSet : ColorSet {
        didSet {
            if(isHighlighted) {
                backgroundColor = colorSet.secondary
            } else {
                backgroundColor = colorSet.primary
            }
        }
    }
    
    //MARK: Button initialization
    required init?(coder: NSCoder) {
        self.colorSet = BrandColor.blue
        super.init(coder: coder)
        
    }
    
    init(_ c: ColorSet) {
        self.colorSet = c
        super.init(frame: CGRect())
        // Setup button appearance
        backgroundColor = c.primary
        tintColor = .white
        layer.cornerRadius = 10
        layer.borderWidth = 0
        // layer.borderColor = c.primary.cgColor
        showsTouchWhenHighlighted = false
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            if(isHighlighted) {
                backgroundColor = colorSet.secondary
            } else {
                backgroundColor = colorSet.primary
            }
        }
    }
    
    func setCircleStyle() {
        let radius = min(frame.size.width / 2, frame.size.height / 2)
        let center = (frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2)
        self.layer.cornerRadius = radius
        self.frame.origin.x = center.0 - radius
        self.frame.origin.y = center.1 - radius
        self.frame.size.width = radius * 2
        self.frame.size.height = radius * 2
        self.titleLabel?.font = self.titleLabel?.font.withSize(40.0)
        self.titleLabel?.baselineAdjustment = .alignCenters
    }
}

