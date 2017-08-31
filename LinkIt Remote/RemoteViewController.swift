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
    var settings = [CBUUID : CBCharacteristic]()
    var eventData = Data()
    var eventCharacteristic : CBCharacteristic?
    

    //MARK: actions
    @IBAction func refreshDevice(_ sender: Any) {
        connect()
    }
    
    func buttonUp(button : UIButton, forEvent event: UIControlEvents) {
        sendRemoteEvent(index: button.tag, event: .valueChange, data: 0)
    }
    
    func buttonDown(button : UIButton, forEvent event: UIControlEvents) {
        sendRemoteEvent(index: button.tag, event: .valueChange, data: 1)
    }
    
    func sliderChanged(slider: UISlider) {
        sendRemoteEvent(index: slider.tag, event: .valueChange, data: UInt16(slider.value))
    }
    
    func switched(button : UISwitch) {
        let event = ControlEvent.valueChange
        sendRemoteEvent(index: button.tag, event: event, data: UInt16(button.isOn ? 1 : 0))
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: {() -> Void in
            self.clear()
        })
    }
    
    //MARK: view delegates
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

    
    //MARK: BLE delegates
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state= \(central.state) from RemoteViewController")
        
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        if peripheral == device?.peripheral {
            peripheral.delegate = self
            peripheral.discoverServices([RCUUID.SERVICE])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first(where: { $0.uuid == RCUUID.SERVICE}) {
            print("service found \(service), check characteristics")
            let toDiscover = [RCUUID.CANVAS_ROW,
                              RCUUID.CANVAS_COLUMN,
                              RCUUID.CONTROL_COUNT,
                              RCUUID.CONTROL_TYPE_ARRAY,
                              RCUUID.CONTROL_COLOR_ARRAY,
                              RCUUID.CONTROL_RECT_ARRAY,
                              RCUUID.CONTROL_NAME_LIST,
                              RCUUID.CONTROL_EVENT_ARRAY]
            
            peripheral.discoverCharacteristics(toDiscover, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("did discovered")
        for c in service.characteristics ?? [] {
            // read UI layout settings from remote device
            self.settings[c.uuid] = c
            
            if c.uuid == RCUUID.CONTROL_EVENT_ARRAY {
                print("found RC Array characteristics")
                self.eventCharacteristic = c
            }
            
            peripheral.readValue(for: c)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // check if there are still nil value(not read yet)
        if self.settings.count > 0 && self.settings.filter({$1.value == nil}).isEmpty {
            print("all field ready")
            if self.remoteView.subviews.isEmpty {
                print("view empty, start creating controls")
                collectDeviceInfo()
            }
            
        } else {
            print("still reading characteristic...")
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("written with \(error)")
    }
    
    //MARK: Methods
    
    private func clear() {
        
        // Clear UI layout info
        settings.removeAll(keepingCapacity: true)
        eventData.removeAll()
        eventCharacteristic = nil
        device?.controls.removeAll()
        
        // Clear UIView tree
        for s in self.remoteView.subviews {
            s.removeFromSuperview()
        }
    }
    
    // MARK: method
    private func connect() {
        clear()
        if let peripheral = device?.peripheral {
            spinner.startAnimating()
            manager?.connect(peripheral, options: nil)
        }
    }
    
    private func collectDeviceInfo() {
        if let d = self.device {
            d.row = readInt(data: settings[RCUUID.CANVAS_ROW]!.value!)
            d.col = readInt(data: settings[RCUUID.CANVAS_COLUMN]!.value!)
            let controlCount = readInt(data: settings[RCUUID.CONTROL_COUNT]!.value!)
            let typeArray = settings[RCUUID.CONTROL_TYPE_ARRAY]!.value!
            let colorArray = settings[RCUUID.CONTROL_COLOR_ARRAY]!.value!
            let rectArray = settings[RCUUID.CONTROL_RECT_ARRAY]!.value!
            let nameData = settings[RCUUID.CONTROL_NAME_LIST]!.value!
            let nameString = String(data: nameData, encoding: String.Encoding.utf8)
            let names = nameString?.components(separatedBy: "\n") ?? []
            
            print("names = \(names)")
            
            // collect device control info
            d.controls.removeAll()
            for i in 0..<controlCount {
                let type = typeArray[i]
                let color = colorArray[i]
                let x = Int(rectArray[i * 4 + 0])
                let y = Int(rectArray[i * 4 + 1])
                let r = Int(rectArray[i * 4 + 2])
                let c = Int(rectArray[i * 4 + 3])
                let ci = ControlInfo(type: ControlType(rawValue: type) ?? ControlType.label,
                                     color: ColorType(rawValue: color) ?? ColorType.gold,
                                     cell: CGRect(x: x, y: y, width: r, height: c),
                                     text: names[i])
                d.controls.append(ci)
                print("\(ci)")
            }
            
            // setup output event array
            // the array is a uint8[4] * (number of controls)
            // the uint8[4] consists of (event, event data, user data, sequence)
            eventData.resetBytes(in: 0..<(controlCount * 4))

            
            print("creating controls...")
            createControls()
        }
    }
    
    private func createControls() {
        if let d = self.device {
            let padding = CGFloat(4.0)
            let vw = CGFloat(self.remoteView.frame.width)
            let vh = CGFloat(self.remoteView.frame.height)
            let cw = vw / CGFloat(d.col)
            let ch = vh / CGFloat(d.row)
            
            var controlIndex = 0
            
            for info in d.controls {
                
                // calculate control frame
                var rect = info.cell
                rect = rect.applying(CGAffineTransform(scaleX: cw, y: ch))
                rect = rect.insetBy(dx: padding, dy: padding)
                
                // create control
                let view = createControlBy(info: info, frame: rect, useTag: controlIndex)
                controlIndex += 1
                
                // insert to view
                self.remoteView.addSubview(view)
            }
            
        }
        
        spinner.stopAnimating()
    }
    
    private func createControlBy(info: ControlInfo, frame: CGRect, useTag: Int) -> UIView {
        switch(info.type) {
        case .label:
            let label = UILabel(getColorSet(info.color))
            label.frame = frame
            label.text = info.text
            label.layer.cornerRadius = 10
            return label
            
        case .pushButton,
             .circleButton:
            let button = RemoteUIButton(getColorSet(info.color))
            button.frame = frame
            button.setTitle(info.text, for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.tag = useTag
            
            // Setup the button action
            button.addTarget(self,
                             action: #selector(RemoteViewController.buttonUp(button:forEvent:)),
                             for: .touchUpInside)
            button.addTarget(self,
                             action: #selector(RemoteViewController.buttonDown(button:forEvent:)),
                             for: .touchDown)
            
            if info.type == .circleButton {
                button.setCircleStyle()
            }
            return button
            
        case .slider:
            let slider = SliderPanel.loadFromNib(withColor: getColorSet(info.color))
            slider.titleLabel.text = info.text
            slider.frame = frame
            slider.slider.tag = useTag
            slider.slider.addTarget(self, action: #selector(RemoteViewController.sliderChanged(slider:)), for: .touchUpInside)
            return slider
            
        case .switchButton:
            let switchPanel = UIView(frame:frame)
            let padding = CGFloat(4.0)
            var btnFrame = frame
            btnFrame.origin = .zero
            btnFrame = btnFrame.insetBy(dx: padding, dy: padding)
            
            var labelFrame = btnFrame
            labelFrame.size.height /= CGFloat(3.0)
            labelFrame.origin.y = 0
            
            let switchLabel = UILabel(frame: labelFrame)
            switchLabel.text = info.text
            switchLabel.baselineAdjustment = .alignBaselines
            switchLabel.textAlignment = .center
            switchLabel.textColor = .white
            
            let switchBtn = UISwitch(frame: btnFrame)
            let colorSet = getColorSet(info.color)
            switchBtn.tintColor = colorSet.primary
            switchBtn.onTintColor = colorSet.primary
            let sx = (btnFrame.size.width - padding * 2) / switchBtn.bounds.size.width
            let sy = (btnFrame.size.height - padding * 2) / switchBtn.bounds.size.height
            let scale = min(sx, sy)
            switchBtn.transform = CGAffineTransform(scaleX: scale, y:scale)
            switchBtn.center.x = btnFrame.origin.x + btnFrame.size.width / 2
            switchBtn.center.y = btnFrame.origin.y + btnFrame.size.height / 2 +
                (switchLabel.frame.size.height - padding) / scale
            switchPanel.addSubview(switchBtn)
            switchPanel.addSubview(switchLabel)
            
            switchBtn.tag = useTag
            switchBtn.addTarget(self,
                             action: #selector(RemoteViewController.switched(button:)),
                             for: .valueChanged)
            
            return switchPanel
        }
    }
    
    private func sendRemoteEvent(index : Int, event : ControlEvent, data: UInt16) {
        if self.eventCharacteristic == nil {
            print("characteristic not available")
            return
        }
        
        if let p = self.device?.peripheral {
            eventData[index * 4 + 0] += 1                       // sequence number - increment it
            eventData[index * 4 + 1] = event.rawValue           // Event
            eventData[index * 4 + 2] = UInt8(data & 0xFF);      // Event data, high byte
            eventData[index * 4 + 3] = UInt8(data >> 8) & 0xFF; // Event data, low byte
            
            for i in eventData {
                print("\(i)")
            }
            p.writeValue(eventData, for: self.eventCharacteristic!, type: .withResponse)
        }
    }

}
