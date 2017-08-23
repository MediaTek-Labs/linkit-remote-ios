//
//  DeviceTableViewController.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

class DeviceTableViewController: UITableViewController {
    //MARK: properties
    var devices : [Device] = [Device]()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadSampleDevices()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "DeviceTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? DeviceTableViewCell else {
            fatalError("wrong cached cell type")
        }
        
        // Configure the cell...
        let device = devices[indexPath.row]
        cell.nameLabel.text = device.name
        cell.addressLabel.text = device.address
        
        // return it to framework for caching/drawing
        return cell
    }



    //MARK: private methods
    private func loadSampleDevices() {
        
        for index in 0..<3 {
            let device = Device(name: "Test \(index)", address: "--:--:--:--")
            print("device: \(device)")
            devices.append(device)
        }
    }

}

