//
//  DeviceTableViewController.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceTableViewController: UITableViewController, CBCentralManagerDelegate {
    
    //MARK: defines
    
    let SERVICE_UUID = CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")
    
    //MARK: properties
    
    var devices : [Device] = [Device]()
    var manager : CBCentralManager!
    
    //MARK: actions
    
    @IBAction func openHelpPage() {
        let url = NSURL(string:"http://labs.mediatek.com/")! as URL
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    
    //MARK: view protocols

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadSampleDevices()
        
        // Instantialte BLE manager
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value:true)])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: CentralManagerDelegates
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state= \(central.state)")
        if central.state != .poweredOn {
            print("bluetooth not powered on")
        } else {
            print("ble start scanning")
            // central.scanForPeripherals(withServices: [SERVICE_UUID], options: nil)
            central.scanForPeripherals(withServices: nil, options: nil)
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("device found with data \(advertisementData)")
        let device = Device(name: peripheral.name ?? "Unnamed", address: String(RSSI.intValue))
        self.addNewDevice(device)

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
    
    private func addNewDevice(_ : Device) {
        // append new device info to data and view
        let newIndexPath = IndexPath(row: devices.count, section: 0)
        devices.append(device)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
    }

}

