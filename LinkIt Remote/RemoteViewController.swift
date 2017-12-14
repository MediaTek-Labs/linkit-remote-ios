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
    @IBOutlet weak var blurText: UILabel!
    
    //MARK: properties
    var device : Device?
    var manager : CBCentralManager?
    
    var queryContext : RemoteQueryContext?
    var settings = [CBUUID : CBCharacteristic]()
    var eventData = Data()
    var eventSeq = UInt8(0)
    var eventCharacteristic : CBCharacteristic?
    var isCreatingControlforOrientation = false
    var isSendingValue = false
    var sendingActions = [() -> Void]()
    var sliderEventTimer : Timer?
    let SLIDER_UPDATE_INTERVAL = 0.1    // update slider value when dragging. Unit is second.

    //MARK: actions
    @IBAction func refreshDevice(_ sender: Any) {
        connect()
    }
    
    @objc func buttonUp(button : UIButton, forEvent event: UIControlEvents) {
        sendRemoteEvent(index: button.tag, event: .valueChange, data: 0)
    }
    
    @objc func buttonDown(button : UIButton, forEvent event: UIControlEvents) {
        sendRemoteEvent(index: button.tag, event: .valueChange, data: 1)
    }
    
    @objc func delayedSend(_ timer : Timer) {
        if let info = timer.userInfo as? (Int, Int) {
            let (tag, sliderVal) = info
            self.sendRemoteEvent(index: tag, event: .valueChange, data: sliderVal)
        }
        // clear the flag so we can send next event
        self.sliderEventTimer = nil
    }
    
    @objc func sliderChanged(slider: UISlider) {
        let sliderEvent : (Int, Int) = (slider.tag, Int(slider.value))
        // check if 0.3 second has passed before previous
        if self.sliderEventTimer == nil {
            self.sliderEventTimer = Timer.scheduledTimer(timeInterval: SLIDER_UPDATE_INTERVAL,
                                                         target: self,
                                                         selector: #selector(self.delayedSend(_:)),
                                                         userInfo: sliderEvent,
                                                         repeats: false)
            
        }
    }
    
    @objc func sliderReleased(slider: UISlider) {
        let sliderEvent : (Int, Int) = (slider.tag, Int(slider.value))
        // cancel previous events and send event immediately
        self.sliderEventTimer?.invalidate()
        self.sliderEventTimer = nil
        let (tag, value) = sliderEvent
        self.sendRemoteEvent(index: tag, event: .valueChange, data: value)
    }
    
    @objc func switched(button : UISwitch) {
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
                let msg = NSLocalizedString("Disconnected Message", comment: "")
                showErrorMsg(msg)
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
            // check if PROTOCOL_VERSION is available
            // if not, we need to ask user to upgrade LRemote Arduino library.
            if let clist = service.characteristics {
                if 0 == clist.filter({ $0.uuid == RCUUID.PROTOCOL_VERSION}).count {
                    let msg = NSLocalizedString("Mismatched Version", comment: "")
                    showErrorMsg(msg)
                    return
                }
            }
            
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
            return
        }
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.queryContext != nil {
            // mark read
            self.queryContext!.toRead.remove(characteristic)
            
            // insert to setting dict
            self.settings[characteristic.uuid] = characteristic
            
            // special handling cases
            switch(characteristic.uuid) {
            case RCUUID.CONTROL_EVENT_ARRAY:
                self.eventCharacteristic = characteristic
            case RCUUID.CONTROL_UI_UPDATE:
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
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
            
        } else if characteristic.uuid == RCUUID.CONTROL_UI_UPDATE {
            
            // for UI text update
            if let updateInfoData = characteristic.value {
                // retrieve control index and text length from header
                let (controlIndex, dataSize) = updateInfoData.withUnsafeBytes({(body:UnsafePointer<UIUpdateInfoHeader>) -> (Int, Int) in
                    return (Int(body.pointee.controlIndex), Int(body.pointee.dataSize))
                })

                // retrive the text, which is immediately following the header
                let text : String = updateInfoData.withUnsafeBytes({(body: UnsafePointer<CChar>) -> String in
                    // skip the header and copy the text data
                    let textData = Data(bytes: body.advanced(by: MemoryLayout<UIUpdateInfoHeader>.size), count: dataSize)
                    // decode as UTF-8 string.
                    // if fails, we show an error string.
                    return String(data: textData, encoding: String.Encoding.utf8) ?? NSLocalizedString("Transmission Error", comment: "")
                })
                
                // find the view object with the control index, and check if it is an UILabel
                if let controls = self.device?.controls {
                    for info in controls {
                        if info.index == controlIndex {
                            if let label = info.view as? UILabel {
                                label.text = text
                            }
                        }
                    }
                }
                
            }
        } else {
            print("not connecting, ignore attribute read event")
            return;
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if(characteristic == self.eventCharacteristic) {
            if self.sendingActions.isEmpty {
                self.isSendingValue = false
            } else {
                // keep send next request
                print("send next action")
                let action = self.sendingActions.removeFirst()
                action();
            }
        }
        if let e = error {
            print("error writing characteristic \(characteristic.uuid) : error: \(e)")
        }
    }
    
    //MARK: Methods
    
    private func showErrorMsg(_ msg: String) {
        self.blurText.text = msg
        self.blurView.isHidden = false
        self.spinner.isHidden = true
    }
    
    private func hideErrorMsg() {
        self.blurView.isHidden = true
    }
    
    private func clear() {
        
        // Clear UI layout info
        settings.removeAll(keepingCapacity: true)
        eventData.removeAll()
        eventCharacteristic = nil
        device?.controls.removeAll()
        queryContext = nil
        hideErrorMsg()
        
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
                                            RCUUID.CONTROL_UI_UPDATE,
                                            RCUUID.CONTROL_CONFIG_DATA_ARRAY,
                                            RCUUID.CONTROL_ORIENTATION,
                                            RCUUID.PROTOCOL_VERSION]
            manager?.connect(peripheral, options: nil)
        }
    }
    
    private func collectDeviceInfo() {
        if let d = self.device {
            d.row = readInt(data: settings[RCUUID.CANVAS_ROW]!.value!)
            d.col = readInt(data: settings[RCUUID.CANVAS_COLUMN]!.value!)
            d.orientation = readInt(data: settings[RCUUID.CONTROL_ORIENTATION]!.value!) == 1 ?
                                    .landscapeRight : .portrait
            let version = readInt(data: settings[RCUUID.PROTOCOL_VERSION]!.value!)
            let controlCount = readInt(data: settings[RCUUID.CONTROL_COUNT]!.value!)
            
            let typeArray = settings[RCUUID.CONTROL_TYPE_ARRAY]!.value!
            let colorArray = settings[RCUUID.CONTROL_COLOR_ARRAY]!.value!
            let rectArray = settings[RCUUID.CONTROL_RECT_ARRAY]!.value!
            let nameData = settings[RCUUID.CONTROL_NAME_LIST]!.value!
            let nameString = String(data: nameData, encoding: String.Encoding.utf8)
            let names = nameString?.components(separatedBy: "\n") ?? []
            let configArray = settings[RCUUID.CONTROL_CONFIG_DATA_ARRAY]!.value!
            
            if version != Device.PROTOCAL_VERSION {
                let msg = NSLocalizedString("Mismatched Version", comment: "")
                showErrorMsg(msg)
            }
            
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
                                     config: configData[i],
                                     index: -1,
                                     view: nil)
                d.controls.append(ci)
            }
            
            eventData.reserveCapacity(6);
            eventData.resetBytes(in: 0..<6)
            eventSeq = 0
            
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
            
            for index in d.controls.indices {
                let info = d.controls[index]
                
                // calculate control frame
                var rect = info.cell
                rect = rect.applying(CGAffineTransform(scaleX: cw, y: ch))
                rect = rect.insetBy(dx: padding, dy: padding)
                
                // create control, and set their "tag" so
                // we can identify them with the remote Arduino device
                let view = createControlBy(info: info, frame: rect, useTag: controlIndex)
                d.controls[index].index = controlIndex
                d.controls[index].view = view
                
                // insert to view
                self.remoteView.addSubview(view)
                
                // increase tag/index
                controlIndex += 1
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
            label.tag = useTag
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
            slider.valueLabel.text = "\(Int(slider.slider.value))"
            slider.slider.addTarget(self, action: #selector(RemoteViewController.sliderChanged(slider:)),
                                    for: .valueChanged)
            slider.slider.addTarget(self, action: #selector(RemoteViewController.sliderReleased(slider:)),
                                    for: [.touchUpInside, .touchUpOutside])
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
            let sy = (btnFrame.size.height - padding * 2 - labelFrame.size.height) / switchBtn.bounds.size.height
            let scale = min(sx, sy)
            switchBtn.transform = CGAffineTransform(scaleX: scale, y:scale)
            switchBtn.center.x = btnFrame.origin.x + btnFrame.size.width / 2
            switchBtn.center.y = btnFrame.origin.y + btnFrame.size.height / 2 +
                (switchLabel.frame.size.height + padding) / scale
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
        
        let sendAction = { () -> Void in
            if let p = self.device?.peripheral {
                var eventData = Data()
                if let d = self.eventCharacteristic?.value {
                    eventData = d
                }
                // 6 bytes of EventInfo
                eventData.reserveCapacity(6)
                eventData[0] = self.eventSeq                       // sequence number - increment it
                self.self.eventSeq += 1
                eventData[1] = UInt8(index)
                eventData[2] = event.rawValue           // Event
                // eventData[3] =                       // These are processed by Arduno side - don't touch
                eventData[4] = UInt8(data & 0xFF);      // Event data, high byte
                eventData[5] = UInt8((data >> 8) & 0xFF); // Event data, low byte
                
                p.writeValue(eventData, for: self.eventCharacteristic!, type: .withResponse)
            }
        }
        
        if(self.isSendingValue) {
            self.sendingActions.append(sendAction)
        } else {
            self.isSendingValue = true
            sendAction()
        }
        
        
    }

}
