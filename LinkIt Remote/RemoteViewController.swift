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

struct RemoteQueryContext {
    var toDiscover = Set<CBUUID>()
    var toRead = Set<CBCharacteristic>()
}

class RemoteViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet var canvas: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    //MARK: properties
    var device : Device?
    var manager : CBCentralManager?
    
    var queryContext : RemoteQueryContext?
    var settings = [CBUUID : CBCharacteristic]()
    var eventData = Data()
    var eventCharacteristic : CBCharacteristic?
    var isCreatingControlforOrientation = false
    

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
        sendRemoteEvent(index: slider.tag, event: .valueChange, data: Int(slider.value))
    }

    
    func switched(button : UISwitch) {
        let event = ControlEvent.valueChange
        sendRemoteEvent(index: button.tag, event: event, data: button.isOn ? 1 : 0)
    }
    
    @IBAction func done(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: {() -> Void in
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
        manager?.delegate = self
        
        // check if device info is known
        if self.device?.controls.isEmpty ?? true {
            print("Get dev info")
            clear()
            connect()
        }
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
    
    override func viewDidLayoutSubviews() {
        // CAUTION: this method can be called mutiple times, 
        // even during control creation process.
        // Therefore a flag is being used to ensure controls
        // are only created once.
        if self.remoteView.subviews.isEmpty && self.isCreatingControlforOrientation {
            self.isCreatingControlforOrientation = false
            createControls()
        }
        
    }
    
    //MARK: BLE delegates
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state= \(central.state) from RemoteViewController")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?){
        if device?.peripheral == peripheral {
            print("remote device disconnected")
            if !remoteView.subviews.isEmpty {
                blurView.isHidden = false
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        if peripheral == device?.peripheral {
            peripheral.delegate = self
            if self.queryContext != nil {
                peripheral.discoverServices([RCUUID.SERVICE])
            } else if !remoteView.subviews.isEmpty {
                // we already created control - re-enable it.
                for v in remoteView.subviews {
                    if let c = v as? UIControl {
                        c.isEnabled = true
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first(where: { $0.uuid == RCUUID.SERVICE}) {
            if let context = self.queryContext {
                print("querying service found \(service), check characteristics")
                peripheral.discoverCharacteristics(Array(context.toDiscover), for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if self.queryContext != nil {
            for characteristic in service.characteristics ?? [] {
                self.queryContext!.toDiscover.remove(characteristic.uuid)
                self.queryContext!.toRead.insert(characteristic)
            }
            
            // if all discovered, we start reading all the characteristics
            if self.queryContext!.toDiscover.isEmpty {
                for charToRead in self.queryContext!.toRead {
                    peripheral.readValue(for: charToRead)
                }
            }
        } else {
            print("not connecting, ignore attribute discover event")
            return;
        }
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.queryContext != nil {
            // mark read
            self.queryContext!.toRead.remove(characteristic)
            
            // insert to setting dict
            self.settings[characteristic.uuid] = characteristic
            if characteristic.uuid == RCUUID.CONTROL_EVENT_ARRAY {
                self.eventCharacteristic = characteristic
            }
            
            // check if all attributes are ready - if so, start
            // creating controls
            if self.queryContext!.toRead.isEmpty {
                print("all field ready, exiting query stage")
                self.queryContext = nil
                if self.remoteView.subviews.isEmpty {
                    collectDeviceInfo()
                }
            }
            
        } else {
            print("not connecting, ignore attribute read event")
            return;
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print("error writing characteristic \(characteristic.uuid) : error: \(e)")
        }
    }
    
    //MARK: Methods
    
    private func clear() {
        
        // Clear UI layout info
        settings.removeAll(keepingCapacity: true)
        eventData.removeAll()
        eventCharacteristic = nil
        device?.controls.removeAll()
        queryContext = nil
        blurView.isHidden = true
        
        if let p = device?.peripheral {
            manager?.cancelPeripheralConnection(p)
        }
        
        // Clear UIView tree
        for s in self.remoteView.subviews {
            s.removeFromSuperview()
        }
    }
    
    private func connect() {
        clear()
        if let peripheral = device?.peripheral {
            spinner.startAnimating()
            self.queryContext = RemoteQueryContext()
            self.queryContext!.toDiscover = [RCUUID.CANVAS_ROW,
                                            RCUUID.CANVAS_COLUMN,
                                            RCUUID.CONTROL_COUNT,
                                            RCUUID.CONTROL_TYPE_ARRAY,
                                            RCUUID.CONTROL_COLOR_ARRAY,
                                            RCUUID.CONTROL_RECT_ARRAY,
                                            RCUUID.CONTROL_NAME_LIST,
                                            RCUUID.CONTROL_EVENT_ARRAY,
                                            RCUUID.CONTROL_CONFIG_DATA_ARRAY,
                                            RCUUID.CONTROL_ORIENTATION]
            manager?.connect(peripheral, options: nil)
        }
    }
    
    private func collectDeviceInfo() {
        if let d = self.device {
            d.row = readInt(data: settings[RCUUID.CANVAS_ROW]!.value!)
            d.col = readInt(data: settings[RCUUID.CANVAS_COLUMN]!.value!)
            d.orientation = readInt(data: settings[RCUUID.CONTROL_ORIENTATION]!.value!) == 1 ?
                                    .landscapeRight : .portrait
            let controlCount = readInt(data: settings[RCUUID.CONTROL_COUNT]!.value!)
            let typeArray = settings[RCUUID.CONTROL_TYPE_ARRAY]!.value!
            let colorArray = settings[RCUUID.CONTROL_COLOR_ARRAY]!.value!
            let rectArray = settings[RCUUID.CONTROL_RECT_ARRAY]!.value!
            let nameData = settings[RCUUID.CONTROL_NAME_LIST]!.value!
            let nameString = String(data: nameData, encoding: String.Encoding.utf8)
            let names = nameString?.components(separatedBy: "\n") ?? []
            let configArray = settings[RCUUID.CONTROL_CONFIG_DATA_ARRAY]!.value!
            
            // collect device control info
            d.controls.removeAll()
            
            // decode 64-byte (4 * UInt16) config data for each control first
            var configData = [ControlConfig]()
            // Make sure the data array has exact same size as desired
            assert(MemoryLayout<ControlConfig>.size * controlCount == configArray.count)
            configArray.withUnsafeBytes({ (data: UnsafePointer<ControlConfig>) in
                for i in 0..<controlCount {
                    let c = data.advanced(by: i).pointee
                    configData.append(c)
                }
            })
            
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
                                     text: names[i],
                                     config: configData[i])
                d.controls.append(ci)
            }
            
            // setup output event array
            // the array is a uint8[4] * (number of controls)
            // the uint8[4] consists of (event, event data, user data, sequence)
            eventData.resetBytes(in: 0..<(controlCount * 4))

            
            // set and lock display orientation
            print("rotate view before we create controls")
            self.isCreatingControlforOrientation = true
            refreshOrientation()
        }
    }
    
    
    // force refresh view orientation
    private func refreshOrientation() {
        let orientation = self.device?.orientation ?? UIInterfaceOrientation.portrait
        
        AppUtility.lockOrientation(orientation == .portrait ?
            UIInterfaceOrientationMask.portrait :
            UIInterfaceOrientationMask.landscapeRight,
                                   andRotateTo: orientation)
        
        // force refresh the view and subview layout
        // we'll create the controls AFTER the subviews layout has completed
        self.view.setNeedsLayout()
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
        
        // stop querying
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
            slider.slider.minimumValue = Float(info.config.data1)
            slider.slider.maximumValue = Float(info.config.data2)
            slider.slider.value = Float(info.config.data3)
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
    
    private func sendRemoteEvent(index : Int, event : ControlEvent, data: Int) {
        if self.eventCharacteristic == nil {
            print("characteristic not available")
            return
        }
        
        if let p = self.device?.peripheral {
            eventData[index * 4 + 0] += 1                       // sequence number - increment it
            eventData[index * 4 + 1] = event.rawValue           // Event
            eventData[index * 4 + 2] = UInt8(data & 0xFF);      // Event data, high byte
            eventData[index * 4 + 3] = UInt8((data >> 8) & 0xFF); // Event data, low byte
            p.writeValue(eventData, for: self.eventCharacteristic!, type: .withResponse)
        }
    }

}
