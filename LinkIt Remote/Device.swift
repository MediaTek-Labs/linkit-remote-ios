//
//  Device.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit
import CoreBluetooth

class Device {
    //MARK: properties
    
    var name : String
    var address : String
    var peripheral : CBPeripheral?
    var rssi : Int?

    //MARK: initialization
    
    init(name: String, address: String, peripheral: CBPeripheral? = nil, rssi: Int? = nil) {
        self.name = name
        self.address = address
        self.peripheral = peripheral
    }
    
    //MARK: methods
    func getButtonCount() -> Int {
        if self.peripheral == nil {
            return 3
        }
        
        return 4
    }
}
