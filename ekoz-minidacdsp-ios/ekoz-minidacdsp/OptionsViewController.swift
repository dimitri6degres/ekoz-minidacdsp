//
//  OptionsViewController.swift
//  minidacDSP
//
//  Created by Dimitri on 11/02/2021.
//

import UIKit

class OptionsViewController: UIViewController {

    
    var callback : ((String)->())?
    
    
    @IBOutlet weak var btnBluetooth: UIButton!
    @IBOutlet weak var btnShut: UIButton!
    @IBOutlet weak var btnReset: UIButton!
    @IBOutlet weak var btnWifi: UIButton!
    @IBOutlet weak var versionLbl: UILabel!
    
    var isWifi = true
    var isBluetooth = true
    
    var versionStr : String!
    var tapGesture : UITapGestureRecognizer!
    var longGesture : UILongPressGestureRecognizer!
    
    var tapGestureBT : UITapGestureRecognizer!
    var longGestureBT : UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        versionLbl.text = versionStr
        
        btnWifi.setImage(isWifi ? UIImage(systemName: "wifi") : UIImage(systemName: "wifi.slash"), for: .normal)
        btnBluetooth.setImage(isBluetooth ? UIImage(systemName: "speaker.fill") : UIImage(systemName: "speaker.slash.fill"), for: .normal)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector (tap))
        longGesture = UILongPressGestureRecognizer(target: self, action: #selector(long))
        tapGesture.numberOfTapsRequired = 1
        btnWifi.addGestureRecognizer(tapGesture)
        btnWifi.addGestureRecognizer(longGesture)
        
        tapGestureBT = UITapGestureRecognizer(target: self, action: #selector (tapBT))
        longGestureBT = UILongPressGestureRecognizer(target: self, action: #selector(longBT))
        tapGesture.numberOfTapsRequired = 1
        btnBluetooth.addGestureRecognizer(tapGestureBT)
        btnBluetooth.addGestureRecognizer(longGestureBT)
    }

    
    @IBAction func shut_modif(_ sender: Any) {
        self.callback?("shut")
        self.dismiss(animated: true, completion: nil)
    }
//    @IBAction func bluetooth_modif(_ sender: Any) {
//        self.callback?("bluetooth")
//        self.dismiss(animated: true, completion: nil)
//    }
    @IBAction func reset_modif(_ sender: Any) {
        self.callback?("reset")
        self.dismiss(animated: true, completion: nil)
    }
//    @IBAction func wifi_modif(_ sender: Any) {
//        self.callback?("wifi")
//        self.dismiss(animated: true, completion: nil)
//    }
    
    
    @objc func tap() {
        print("Tap happend")
        self.callback?("wifi")
        self.dismiss(animated: true, completion: nil)
    }

    @objc func long(gesture: UIGestureRecognizer) {
        if let longPress = gesture as? UILongPressGestureRecognizer {
            if longPress.state == UIGestureRecognizer.State.began {
                
                print("Long press")
                //  self.btnWifi.removeGestureRecognizer(longGesture)
                self.callback?("wifi2")
                self.dismiss(animated: true, completion: nil)
                
            } else {
                
            }
        }
    }



    @objc func tapBT() {
        print("Tap happend")
        self.callback?("bluetooth")
        self.dismiss(animated: true, completion: nil)
    }

    @objc func longBT(gesture: UIGestureRecognizer) {
        if let longPress = gesture as? UILongPressGestureRecognizer {
            if longPress.state == UIGestureRecognizer.State.began {
                
                print("Long press")
                //  self.btnWifi.removeGestureRecognizer(longGesture)
                self.callback?("bluetooth2")
                self.dismiss(animated: true, completion: nil)
                
            } else {
                
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
