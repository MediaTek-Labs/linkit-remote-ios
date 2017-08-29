//
//  Device.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit
import CoreBluetooth

// CBUUID constants for Remote Control Service,
// our own BLE service that represents a
// remote control layout
// The base UUID is "3f60ab39-1710-4456-930c-7e9c9539917e"
// and increments the "1710" part.
class RCUUID {
    // Service UUID
    static let SERVICE = CBUUID(string: "3f60ab39-1710-4456-930c-7e9c9539917e")
    
    // UINT32, number of UI controls in the remote
    static let CONTROL_COUNT = CBUUID(string: "3f60ab39-1711-4456-930c-7e9c9539917e")
    
    // Array of UINT8 with length of CONTROL_COUNT
    static let CONTROL_TYPE_ARRAY = CBUUID(string: "3f60ab39-1712-4456-930c-7e9c9539917e")
    
    // UINT32, number of rows in the remote
    static let CANVAS_ROW = CBUUID(string: "3f60ab39-1713-4456-930c-7e9c9539917e")
    
    // UINT32, number of columns in the remote
    static let CANVAS_COLUMN = CBUUID(string: "3f60ab39-1714-4456-930c-7e9c9539917e")
    
    // Array of UINT8, enum of ColorType of each control
    static let CONTROL_COLOR_ARRAY = CBUUID(string: "3f60ab39-1715-4456-930c-7e9c9539917e")
    
    // Array of UINT8[4], (x, y, row, col) of each control
    static let CONTROL_RECT_ARRAY = CBUUID(string: "3f60ab39-1716-4456-930c-7e9c9539917e")
    
    // String of control names, separated by the \n ASCII character
    static let CONTROL_NAME_LIST = CBUUID(string: "3f60ab39-1717-4456-930c-7e9c9539917e")
}

enum ControlType : UInt8 {
    case label = 1
    case pushButton = 2
    case circleButton = 3
    case switchButton = 4
    case slider = 5
}

enum ColorType : UInt8 {
    case gold = 1
    case yellow
    case blue
    case green
    case pink
    case grey
}

func getColorSet(_ t: ColorType) -> ColorSet {
    switch(t) {
    case .gold:
        return BrandColor.gold
    case .blue:
        return BrandColor.blue
    case .green:
        return BrandColor.green
    case .grey:
        return BrandColor.grey
    case .pink:
        return BrandColor.pink
    case .yellow:
        return BrandColor.yellow
    }
}

struct ControlInfo {
    var type : ControlType  // control type, such as button or label
    var color : ColorType   // control color set
    var cell : CGRect       // coordinate in Remote Grid, not actual screen space.
    var text : String       // control label text
}

class Device {
    //MARK: properties
    
    var name : String
    var address : String
    var peripheral : CBPeripheral?
    var rssi : Int?
    
    // MARK: layout and UI control info
    
    var row: Int = 4
    var col: Int = 2
    var controls = [ControlInfo]()

    //MARK: initialization
    
    init(name: String, address: String, peripheral: CBPeripheral? = nil, rssi: Int? = nil) {
        self.name = name
        self.address = address
        self.peripheral = peripheral
    }

}



