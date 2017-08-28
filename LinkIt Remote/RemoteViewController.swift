//
//  RemoteViewController.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit
import CoreBluetooth

func readInt(data : Data) -> Int {
    return Int(data.withUnsafeBytes({(body : UnsafePointer<Int32>) -> Int32 in
        return body.pointee
    }))
}

class RemoteViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet var canvas: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //MARK: properties
    var device : Device?
    var manager : CBCentralManager?
    var buttons = [UIView]()
    
    var settings = [CBUUID : CBCharacteristic]()
    
    let REMOTE_SERVICE = CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")
    let REMOTE_CANVAS_ROW = CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214")
    let REMOTE_CANVAS_COLUMN = CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214")

    //MARK actions
    @IBAction func refreshDevice(_ sender: Any) {
        clear()
        connect()
    }

    
    //MARK navigation
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navBar.title = device?.name ?? "Unknown"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("remote view will appear2!")
        manager?.delegate = self
        connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: CBCentralManagerDelegates
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state= \(central.state) from RemoteViewController")
        
    }
    
    //MARK: private methods
    func remoteButtonTapped(button : UIButton) {
        print("button tapped! \(button.titleLabel?.text ?? "?")")
        
    }
    
    private func createButtonFrom(device : Device) {
        
    }
    
    // MARK: BLE operation
    func connect() {
        if let peripheral = device?.peripheral {
            spinner.startAnimating()
            manager?.connect(peripheral, options: nil)
        } else {
            prepareButtons(row: 4, col: 2)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        if peripheral == device?.peripheral {
            //TODO: filter to our "remote control service"
            peripheral.delegate = self
            peripheral.discoverServices([REMOTE_SERVICE])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first(where: { $0.uuid == REMOTE_SERVICE}) {
            print("service found \(service), check characteristic")
            peripheral.discoverCharacteristics([REMOTE_CANVAS_ROW, REMOTE_CANVAS_COLUMN], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics ?? [] {
            self.settings[c.uuid] = c
            peripheral.readValue(for: c)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // check if there are still nil value(not read yet)
        if self.settings.filter({$1.value == nil}).isEmpty {
            print("everything is read!")
            prepareButtons(row: readInt(data: settings[REMOTE_CANVAS_ROW]!.value!),
                           col: readInt(data: settings[REMOTE_CANVAS_COLUMN]!.value!))
        } else {
            print("still reading characteristic...")
        }
        
    }
    
    func loadDeviceInfo(device: Device) {
        
    }
    
    private func clear() {
        settings.removeAll(keepingCapacity: true)
        for s in self.remoteView.subviews {
            s.removeFromSuperview()
        }
    }
    
    func prepareButtons(row: Int, col: Int) {
        spinner.stopAnimating()
        
        let padding = 4.0
        
        for iy in 0..<row {
            for ix in 0..<col {
                let vw = Double(self.remoteView.frame.width)
                let vh = Double(self.remoteView.frame.height)
                let cw = vw / Double(col)
                let ch = vh / Double(row)
                let bw = cw - (padding * 2)
                let bh = ch - (padding * 2)
                
                
                let rect = CGRect(x: Double(ix) * cw + padding,
                               y:Double(iy) * ch + padding,
                               width: bw,
                               height: bh)
                
                if ix % 2 == 0 {
                    let button = RemoteUIButton(BrandColor.blue)
                    button.frame = rect
                    // Setup the button action
                    button.addTarget(self,
                                     action: #selector(RemoteViewController.remoteButtonTapped(button:)),
                                     for: .touchUpInside)
                    
                    //button.layer.frame = rect
                    button.setTitle("Jingle", for: .normal)//"Btn \(ix, iy)", for: .normal)
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    if ix == 0 {
                        button.setCircleStyle()
                        button.colorSet = BrandColor.green
                        button.setTitle("Hello", for: .normal)
                    }
                    
                    self.buttons.append(button)
                    self.remoteView.addSubview(button)
                } else if iy % 2 == 0 {
                    let switchPanel = UIView(frame:rect)
                    
                    var btnFrame = rect
                    btnFrame.origin = .zero
                    btnFrame = btnFrame.insetBy(dx: CGFloat(padding), dy: CGFloat(padding))
                    
                    var labelFrame = btnFrame
                    labelFrame.size.height /= CGFloat(3.0)
                    labelFrame.origin.y = 0
                    
                    let switchLabel = UILabel(frame: labelFrame)
                    switchLabel.text = "Hello"
                    switchLabel.baselineAdjustment = .alignBaselines
                    switchLabel.textAlignment = .center
                    switchLabel.textColor = .white
                    
                    let switchBtn = UISwitch(frame: btnFrame)
                    switchBtn.tintColor = BrandColor.gold.primary
                    switchBtn.onTintColor = BrandColor.gold.primary
                    let sx = (btnFrame.size.width - CGFloat(padding) * 2) / switchBtn.bounds.size.width
                    let sy = (btnFrame.size.height - CGFloat(padding) * 2) / switchBtn.bounds.size.height
                    let scale = min(sx, sy)
                    switchBtn.transform = CGAffineTransform(scaleX: scale, y:scale)
                    switchBtn.center.x = btnFrame.origin.x + btnFrame.size.width / 2
                    switchBtn.center.y = btnFrame.origin.y + btnFrame.size.height / 2 +
                                         (switchLabel.frame.size.height - CGFloat(padding)) / scale
                    
                    
                    
                    switchPanel.addSubview(switchBtn)
                    switchPanel.addSubview(switchLabel)
                    self.buttons.append(switchPanel)
                    self.remoteView.addSubview(switchPanel)
                } else {
                    let slider = SliderPanel.loadFromNib(withColor: BrandColor.pink)
                    slider.frame = rect
                    self.buttons.append(slider)
                    self.remoteView.addSubview(slider)
                }
            }
        }
        
    }

}
