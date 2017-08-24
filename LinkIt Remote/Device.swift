//
//  Device.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit
import CoreBluetooth

enum ControlType : Int8 {
    case label = 0
    case pushButton
    case circleButton
    case switchButton
    case slider
}

class ControlInfo {
    var type : ControlType
    var frame : CGRect
    
    init(type: ControlType, rect: CGRect) {
        self.type = type
        self.frame = rect
    }
    
    func createUIControl() -> UIView? {
        // factory function that generates iOS controls
        switch self.type {
        case .label:
            return UILabel(frame: frame)
        case .pushButton:
            let b = UIButton(type: .system)
            b.frame = frame
            return b
        case .circleButton:
            return UIButton(type: .system)
        case .switchButton:
            return UISwitch(frame: frame)
        case .slider:
            return UISlider(frame: frame)
        default:
            return nil
        }
    }
}

class Device {
    //MARK: properties
    
    var name : String
    var address : String
    var peripheral : CBPeripheral?
    var rssi : Int?
    var controls = [ControlInfo]()
    
    //MARK: remote layout info

    //MARK: initialization
    
    init(name: String, address: String, peripheral: CBPeripheral? = nil, rssi: Int? = nil) {
        self.name = name
        self.address = address
        self.peripheral = peripheral
    }
    
    //MARK: methods
    func loadSampleControls() {
        for i in 0...2 {
            controls.append(
                ControlInfo(type: .slider, rect: CGRect(x: 0,
                                                        y: 40 * i,
                                                        width: 33,
                                                        height: 33)))
        }
    }
    
    func getButtonCount() -> Int {
        return controls.count
    }
}



