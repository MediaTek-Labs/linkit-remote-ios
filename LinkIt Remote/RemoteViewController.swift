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
    

    //MARK: actions
    @IBAction func refreshDevice(_ sender: Any) {
        connect()
    }
    
    func remoteButtonTapped(button : UIButton) {
        print("button tapped! \(button.titleLabel?.text ?? "?")")
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK view delegates
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
                              RCUUID.CONTROL_NAME_LIST]
            
            peripheral.discoverCharacteristics(toDiscover, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("did discovered")
        for c in service.characteristics ?? [] {
            self.settings[c.uuid] = c
            peripheral.readValue(for: c)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // check if there are still nil value(not read yet)
        if self.settings.filter({$1.value == nil}).isEmpty {
            print("all field ready")
            if self.remoteView.subviews.isEmpty {
                print("view empty, start creating controls")
                collectDeviceInfo()
            }
            
        } else {
            print("still reading characteristic...")
        }
        
    }
    
    //MARK: Methods
    
    private func clear() {
        settings.removeAll(keepingCapacity: true)
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
            let nameString = String(data: nameData, encoding: String.Encoding.utf8) ?? "Unknown"
            let names = nameString.components(separatedBy: "\n")
            
            print("names = \(names)")
            
            // collect device control info
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
            
            print("creating controls...")
            createControls()
        }
    }
    
    private func createControlBy(info: ControlInfo, frame: CGRect) -> UIView {
        switch(info.type) {
        case .label:
            let label = UILabel(getColorSet(info.color))
            label.frame = frame
            return label
        case .pushButton:
            let button = RemoteUIButton(getColorSet(info.color))
            button.frame = frame
            button.setTitle(info.text, for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            // Setup the button action
            button.addTarget(self,
                             action: #selector(RemoteViewController.remoteButtonTapped(button:)),
                             for: .touchUpInside)
            return button
        case .slider:
            let slider = SliderPanel.loadFromNib(withColor: getColorSet(info.color))
            slider.titleLabel.text = info.text
            slider.frame = frame
            return slider
        default:
            let view = UIView(frame: frame)
            let c = getColorSet(info.color)
            view.backgroundColor = c.primary
            view.tintColor = c.secondary
            view.layer.cornerRadius = 10
            view.layer.borderWidth = 0
            return view
        }
    }
    
    private func createControls() {
        if let d = self.device {
            let padding = CGFloat(4.0)
            let vw = CGFloat(self.remoteView.frame.width)
            let vh = CGFloat(self.remoteView.frame.height)
            let cw = vw / CGFloat(d.col)
            let ch = vh / CGFloat(d.row)
            
            for ci in d.controls {
                
                // calculate control frame
                var rect = ci.cell
                rect = rect.applying(CGAffineTransform(scaleX: cw, y: ch))
                rect = rect.insetBy(dx: padding, dy: padding)
                
                // create control
                let view = createControlBy(info: ci, frame: rect)
                self.remoteView.addSubview(view)
            }
            
        }
        
        spinner.stopAnimating()
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
                    
                    self.remoteView.addSubview(switchPanel)
                } else {
                    let slider = SliderPanel.loadFromNib(withColor: BrandColor.pink)
                    slider.frame = rect

                    self.remoteView.addSubview(slider)
                }
            }
        }
        
    }

}
