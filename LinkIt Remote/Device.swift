//
//  Device.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

class Device {
    //MARK: properties
    
    var name : String
    var address : String

    //MARK: initialization
    
    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
