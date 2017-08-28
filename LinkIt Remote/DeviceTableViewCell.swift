//
//  DeviceTableViewCell.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {
    //MARK: properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    
    //MARK: cell methods
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in self.backgroundColor = highlighted ? UIColor(rgb:0xEE8819) : UIColor(rgb:0x282924)
            })
        } else {
            self.backgroundColor = highlighted ? UIColor(rgb:0xEE8819) : UIColor(rgb:0x282924)
        }
        
        
    }

}
