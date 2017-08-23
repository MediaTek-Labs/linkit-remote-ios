//
//  RemoteViewController.swift
//  LinkIt Remote
//
//  Created by Pablo Sun on 2017/8/23.
//  Copyright © 2017年 MediaTek Labs. All rights reserved.
//

import UIKit

class RemoteViewController: UIViewController {
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var remoteView: UIView!
    
    //MARK: properties
    var device : Device?
    var buttons = [UIButton]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navBar.title = device?.name ?? "Unknown"
        print("remote view did load")
        prepareButtons()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        for i in 0...2 {
            let rect = CGRect(x: 0,
                           y:i * 90,
                           width: 90,
                           height: 90)
            let button = UIButton(type: .system)
            button.frame = rect
            // Setup the button action
            button.addTarget(self,
                             action: #selector(RemoteViewController.remoteButtonTapped(button:)),
                             for: .touchUpInside)
            
            // Setup button appearance
            button.backgroundColor = .black
            
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.clear.cgColor
            //button.layer.frame = rect
            button.setTitle("Btn \(i)", for: .normal)
            
            self.buttons.append(button)
            self.remoteView.addSubview(button)
        }
        
    }

}
