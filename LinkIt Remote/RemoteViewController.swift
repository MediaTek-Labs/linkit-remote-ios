//
//  RemoteViewController.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

struct ColorSet {
    var primary : UIColor
    var secondary : UIColor
}

class BrandColor {
    static let gold = ColorSet(primary: UIColor(rgb: 0xF39A1E), secondary: UIColor(rgb: 0xDEC9A5))
    static let yellow = ColorSet(primary: UIColor(rgb: 0xFED100), secondary: UIColor(rgb: 0xE1D4A0))
    static let blue = ColorSet(primary: UIColor(rgb: 0x00A1DE), secondary: UIColor(rgb: 0xABCBDD))
    static let green = ColorSet(primary: UIColor(rgb: 0x69BE28), secondary: UIColor(rgb: 0xB6CEA9))
    static let pink = ColorSet(primary: UIColor(rgb: 0xD71F85), secondary: UIColor(rgb: 0xDCAEC9))
    static let grey = ColorSet(primary: UIColor(rgb: 0x353630), secondary: UIColor(rgb: 0x353630))
}

extension UILabel {
    convenience init(_ c: ColorSet) {
        self.init()
        backgroundColor = c.secondary
        tintColor = .white
        layer.cornerRadius = 10
        layer.borderWidth = 0
    }
}

class RemoteUIButton : UIButton {
    var colorSet : ColorSet {
        didSet {
            if(isHighlighted) {
                backgroundColor = colorSet.secondary
            } else {
                backgroundColor = colorSet.primary
            }
        }
    }
    
    //MARK: Button initialization
    required init?(coder: NSCoder) {
        self.colorSet = BrandColor.blue
        super.init(coder: coder)
        
    }
    
    init(_ c: ColorSet) {
        self.colorSet = c
        super.init(frame: CGRect())
        // Setup button appearance
        backgroundColor = c.primary
        tintColor = .white
        layer.cornerRadius = 10
        layer.borderWidth = 0
        // layer.borderColor = c.primary.cgColor
        showsTouchWhenHighlighted = false
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            if(isHighlighted) {
                backgroundColor = colorSet.secondary
            } else {
                backgroundColor = colorSet.primary
            }
            print("isHighlight change to \(isHighlighted)")
        }
    }
    
    func setCircleStyle() {
        let radius = min(frame.size.width / 2, frame.size.height / 2)
        let center = (frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2)
        self.layer.cornerRadius = radius
        self.frame.origin.x = center.0 - radius
        self.frame.origin.y = center.1 - radius
        self.frame.size.width = radius * 2
        self.frame.size.height = radius * 2
        self.titleLabel?.font = self.titleLabel?.font.withSize(40.0)
        self.titleLabel?.baselineAdjustment = .alignCenters
    }
}

class RemoteViewController: UIViewController {
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet var canvas: UIView!
    
    //MARK: properties
    var device : Device?
    var buttons = [UIView]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navBar.title = device?.name ?? "Unknown"
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // genereate controls AFTER auto-layout of the
        // remoteView finished
        prepareButtons()
        // canvas.backgroundColor = BrandColor.grey.secondary
        setNeedsStatusBarAppearanceUpdate()
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
    
    //MARK: private methods
    func remoteButtonTapped(button : UIButton) {
        print("button tapped! \(button.titleLabel?.text ?? "?")")
        
    }
    
    func prepareButtons() {
        let row = 4
        let col = 4
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
                    /*
                    let sliderPanel = UIView(frame:rect)
                    sliderPanel.layer.cornerRadius = 10
                    sliderPanel.layer.borderWidth = 0
                    
                    var labelFrame = rect
                    labelFrame.origin = .zero
                    
                    
                    var sliderFrame = rect
                    sliderFrame.origin.x = 0
                    sliderFrame.origin.y = rect.size.height / 2
                    sliderFrame.size.height = rect.size.height / 2
                    sliderFrame = sliderFrame.insetBy(dx: 8.0, dy: 0)
                    sliderPanel.backgroundColor = BrandColor.pink.primary
                    //frame: CGRect(x:padding, y:padding, width: rect.size.width - 2 * padding, height: rect.size.height - 2 * padding)
                    let slider = UISlider(frame: sliderFrame)
                    slider.tintColor = BrandColor.pink.secondary
                    sliderPanel.addSubview(slider)
                    */
                    let slider = SliderPanel.loadFromNib(withColor: BrandColor.pink)
                    slider.frame = rect
                    self.buttons.append(slider)
                    self.remoteView.addSubview(slider)
                }
            }
        }
        
    }

}
