//
//  SliderPanel.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/24.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

class SliderPanel: UIView {
    
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var slider: UISlider!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func onValueChanged(_ sender: UISlider) {
        valueLabel.text = "\(Int(sender.value))"
    }
    
    static func loadFromNib(withColor c: ColorSet) -> SliderPanel {
        let nib = UINib.init(nibName: "SliderPanel", bundle: nil)
        let sliderPanel = nib.instantiate(withOwner: nil, options: nil)[0] as! SliderPanel
        
        sliderPanel.backgroundColor = c.primary
        sliderPanel.tintColor = .white
        sliderPanel.layer.cornerRadius = 10
        sliderPanel.layer.borderWidth = 0
        
        sliderPanel.titleLabel.textColor = .white
        sliderPanel.titleLabel.text = "A1"
        sliderPanel.valueLabel.textColor = .white
        sliderPanel.slider.tintColor = c.secondary
        sliderPanel.slider.isContinuous = true
        
        sliderPanel.slider.minimumValue = 0
        sliderPanel.slider.maximumValue = 100
        return sliderPanel
    }
}
