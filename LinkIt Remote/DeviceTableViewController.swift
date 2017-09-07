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
    let SCAN_DURATION = 5.0
    
    //MARK: properties
    var devices : [Device] = [Device]()
    var manager : CBCentralManager!
    
    override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        get {
            return .portrait
        }
    }
    
    //MARK: controls
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var scanProgressView: UIProgressView!

    //MARK: actions
    @IBAction func refreshDeviceList(_ sender: Any) {
        self.startScan()
    }
    
    @IBAction func openHelpPage() {
        let path = "https://docs.labs.mediatek.com/resource/linkit7697-arduino/en/developer-guide/using-linkit-remote"
        
        let url = NSURL(string:path)! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(url)
        }
    }
    
    
    //MARK: view protocols

    override func viewDidLoad() {
        super.viewDidLoad()

        // Instantialte BLE manager
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value:true)])
        
        scanProgressView.isHidden = true
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        manager?.delegate = self
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        stopScan()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    //MARK: table view protocols
    
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
        cell.rssiLabel.text = "\(device.rssi ?? 0) dB"
        
        // return it to framework for caching/drawing
        return cell
    }
    
    
    //MARK: navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        print("seque triggered ! \(segue, sender)")
        
        self.stopScan()
        
        switch(segue.identifier ?? ""){
        case "ShowRemote":
            guard let navController = segue.destination as? UINavigationController else {
                fatalError("not going to UI!")
            }
            
            guard let remoteController = navController.visibleViewController as? RemoteViewController else {
                fatalError("not going to remote view UI!")
            }
            
            guard let cell = sender as? DeviceTableViewCell else {
                fatalError("unexpected sender!")
            }
            
            guard let indexPath = tableView.indexPath(for: cell) else {
                fatalError("cell not found in tableView")
            }
            
            let remoteDevice = devices[indexPath.row]
            remoteController.device = remoteDevice
            remoteController.manager = manager
            // remoteController shall re-assign the delegate after it appears
        default:
            fatalError("not handled segue")
        }
    }
    
    //MARK: CBCentralManagerDelegates
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state= \(central.state) from TableViewController")
        startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("device found with data \(advertisementData)")
        let device = Device(name: peripheral.name ?? "Unnamed",
                            address: peripheral.identifier.uuidString,
                            peripheral: peripheral,
                            rssi: RSSI.intValue)
        self.addNewDevice(device)
    }

    //MARK: private methods
    private func loadSampleDevices() {
        for index in 0..<3 {
            let device = Device(name: "Test \(index)", address: "--:--:--:--")
            addNewDevice(device)
        }
    }
    
    private func addNewDevice(_ device: Device) {
        // append new device info to data and view
        let newIndexPath = IndexPath(row: devices.count, section: 0)
        devices.append(device)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
    
    private func startScan() {
        if self.manager.state != .poweredOn {
            let msg = NSLocalizedString("Bluetooth Message", comment: "")
            let alert = UIAlertController(title: "Bluetooth", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        self.devices.removeAll()
        self.tableView.reloadData()
        self.manager.scanForPeripherals(withServices: [RCUUID.SERVICE], options: nil)
        
        // Scan for 10 seconds and we stop.
        // User cannot trigger scan again while scanning,
        // so disable the refresh button.
        
        self.refreshButton.isEnabled = false
        self.scanProgressView.progress = 0.0
        self.scanProgressView.setProgress(0.0, animated: false)
        self.scanProgressView.isHidden = false
        
        // update the progress bar
        UIView.animate(withDuration: SCAN_DURATION, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in self.scanProgressView.setProgress(1.0, animated: true)})
        
        // set timer to stop scanning
        Timer.scheduledTimer(timeInterval: SCAN_DURATION, target: self, selector: #selector(self.stopScan), userInfo: nil, repeats: false)
    }
    
    func stopScan() {
        // stop scanning, stop timer and then reset counter
        self.manager?.stopScan()
        self.scanProgressView.isHidden = true
        self.scanProgressView.setProgress(0.0, animated: false)
        self.refreshButton.isEnabled = true
    }

}

