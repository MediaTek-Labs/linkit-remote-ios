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

struct ControlInfo {
    var type : ControlType  // control type, such as button or label
    var cell : CGRect       // coordinate in Remote Grid, not actual screen space.
}

class Device {
    //MARK: properties
    var name : String
    var address : String
    var peripheral : CBPeripheral?
    var rssi : Int?
    
    // MARK: layout and UI control info
    var grid = CGSize(width: 3, height: 4)
    var controls = [ControlInfo]()

    //MARK: initialization
    
    init(name: String, address: String, peripheral: CBPeripheral? = nil, rssi: Int? = nil) {
        self.name = name
        self.address = address
        self.peripheral = peripheral
    }
    
    //MARK: methods
    
    
    //MARK: test
    private func generateControlInfo() {
        let c = ControlInfo(type: .label, cell: CGRect(x:0, y:0, width:2, height:1))
        controls.append(c)
    }
}



