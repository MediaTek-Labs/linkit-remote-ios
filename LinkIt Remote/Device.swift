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
    
    // Array of UINT8[4], (event, event data, user data, seq id) that represents event of each control
    static let CONTROL_EVENT_ARRAY = CBUUID(string: "b5d2ff7b-6eff-4fb5-9b72-6b9cff5181e7")
    
    // Array of UINT16[4], (data1, data2, data3, data4) for each control's value or data setting
    // Current use cases:
    //  - Slider : (min value, max value, initial value, reserved)
    static let CONTROL_CONFIG_DATA_ARRAY = CBUUID(string: "5d7a63ff-4155-4c7c-a348-1c0a323a6383")
    
    // Desired orientation for the UI remote view
    //  0: portrait
    //  1: landscape
    static let CONTROL_ORIENTATION = CBUUID(string: "203fbbcd-9967-4eba-b0ff-0f72e5a634eb")
    
    // protocol version, to ensure version match between arduino and mobile.
    static let PROTOCOL_VERSION = CBUUID(string: "ae73266e-65d4-4023-8868-88b070d5d576");
}

enum ControlType : UInt8 {
    case label = 1
    case pushButton = 2
    case circleButton = 3
    case switchButton = 4
    case slider = 5
}

enum ControlEvent : UInt8 {
    case btnDown = 1
    case btnUp
    case valueChange
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

struct ControlConfig {
    var data1 : Int16
    var data2 : Int16
    var data3 : Int16
    var data4 : Int16
}

struct ControlInfo {
    var type : ControlType  // control type, such as button or label
    var color : ColorType   // control color set
    var cell : CGRect       // coordinate in Remote Grid, not actual screen space.
    var text : String       // control label text
    var config : ControlConfig
}

class Device {
    //MARK: properties
    
    static let PROTOCAL_VERSION = 2
    
    var name : String
    var address : String
    var peripheral : CBPeripheral?
    var rssi : Int?
    var orientation = UIInterfaceOrientation.portrait
    
    // MARK: layout and UI control info
    
    var row: Int = 4
    var col: Int = 2
    var controls = [ControlInfo]()

    //MARK: initialization
    
    init(name: String, address: String, peripheral: CBPeripheral? = nil, rssi: Int? = nil) {
        self.name = name
        self.address = address
        self.peripheral = peripheral
        self.rssi = rssi
    }

}



