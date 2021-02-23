//
//  ViewController.swift
//  ekoz-minidacdsp
//
//  Created on 04/02/2021.
//
//  ekoz-minidacdsp by Dimitri Fontaine is licensed under CC BY-NC 4.0.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    let progressHUD = ProgressHUD()
    var progress : Int = 0 {
        didSet {
            print("new progress", progress)
            if progress > 0 { progressHUD.show(in: self.view) }
            else { progressHUD.hide() }
        }
    }
    
    var isWifi = true
    var isBluetooth = true
    var version = "_"
    var temperature = "_"
    
    // Outlet for sliders
    @IBOutlet weak var volSlider: UISlider!
    @IBOutlet weak var chnSegment: UISegmentedControl!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var tempBtn: UIButton!
    @IBOutlet weak var wifiBtn: UIButton!
    
    // Characteristics
    private var sysChar: CBCharacteristic?
    private var tempChar: CBCharacteristic?
    private var wifiChar: CBCharacteristic?
    private var dspChar: CBCharacteristic?
    
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        centralManager = CBCentralManager(delegate: self, queue: nil)

    }
    
 
    
    // update central image to DSP channel used
    func updateImg(){
        switch chnSegment.selectedSegmentIndex {
        case 0:
            img.image = UIImage(named: "DSP0")
        case 1:
            img.image = UIImage(named: "DSP1")
        case 2:
            img.image = UIImage(named: "DSP2")
        case 3:
            img.image = UIImage(named: "DSP3")
        default:
            break
        }
    }
    
    
    
    
    
    // If we're powered on, start scanning
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for ekoz-minidacDSP");
            progress = 1
            centralManager.scanForPeripherals(withServices: nil)
        }
        
        
        
    }
    
    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("found", peripheral.name as Any, peripheral.identifier)
        
        if let peri = peripheral.name, peri == "ekoz-minidacdsp" || peri == "raspberrypi" {
            print("find", peri)
            
            self.peripheral =  peripheral
            self.peripheral.delegate = self
            
            centralManager.stopScan()
            centralManager.connect(self.peripheral, options: nil)
            
        }
        
    }
    
 
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to ekoz-minidacDSP")
            peripheral.discoverServices(nil);
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("Services modified")
        self.viewDidLoad()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            print("Disconnected")
            self.viewDidLoad()
        }
    }
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            print("PERIPHERAL", peripheral.name as Any, peripheral.identifier)
            for service in services {
                print("SERVICE", service.uuid)
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Enabling notify ", characteristic.uuid)
        if error != nil {
            print("Enable notify error")
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
        
        switch characteristic.uuid {
        
        case sysChar?.uuid :
            
            let string = decodeGATT(from: characteristic)
            print("TEMP", string)
            if string.first == "V" { version = string}
            else { temperature = string }
                
                
        case wifiChar?.uuid :
            print("wifi&BT :", decodeGATT(from: characteristic))
            
            let str = decodeGATT(from: characteristic)
            
            let wifirange = str.startIndex..<str.index(str.startIndex, offsetBy: 2)
            isWifi = (str[wifirange] == "W1")
            let bluerange = str.index(str.startIndex, offsetBy: 2)..<str.index(str.startIndex, offsetBy: 4)
            isBluetooth = (str[bluerange] == "B1")
            
    
            
        case dspChar?.uuid :
            print("read DSP : ", decodeGATT(from: characteristic))
            if decodeGATT(from: characteristic) == "0" { return }
            if decodeGATT(from: characteristic) == "Error" { return }
            let string = decodeGATT(from: characteristic).split(separator: "V")
            print("Channel : \(string[0]) & volume : \(string[1]) ")
            chnSegment.selectedSegmentIndex = Int(string[0]) ?? 100
            volSlider.value = Float(string[1]) ?? 100
            updateImg()
            progress -= 1
            
        default:
            print("UUID: \(characteristic.uuid)\n", decodeGATT(from: characteristic))
        }
        
    }
    
    private func decodeGATT(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value else { return "Error" }
        
        
        
        if let string = String(bytes: characteristicData, encoding: .utf8) {
            return string
        } else {
            return "not a valid UTF-8 sequence"
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("Discriptors found for \(characteristic.description)")
    }
    
    // Handling discovery of characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
    
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                
              
                if characteristic.properties.contains(.read) {
                    print("\(characteristic.uuid): properties contains .read")
                    peripheral.readValue(for: characteristic)

                }
                if characteristic.properties.contains(.notify) {
                    print("\(characteristic.uuid): properties contains .notify")
                    peripheral.setNotifyValue(true, for: characteristic)
//                    if characteristic.uuid == CBUUID(string: "00000002-6DEB-11EB-9439-0242AC130002") {
//                        sysChar = characteristic
//                    }
                    
                }
                if characteristic.properties.contains(.writeWithoutResponse) {
                    print("\(characteristic.uuid): properties contains .write")
                    
                    if characteristic.uuid == CBUUID(string: "00000002-6DEB-11EB-9439-0242AC130002") {
                        sysChar = characteristic
                    }
                    if characteristic.uuid == CBUUID(string: "00000003-6DEB-11EB-9439-0242AC130002") {
                        wifiChar = characteristic
                    }
                    if characteristic.uuid == CBUUID(string: "00000004-6DEB-11EB-9439-0242AC130002") {
                        dspChar = characteristic
                    }
                    
                }
                
            }
        }
    }
    
    
    private func writeDSPchange( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        
        // Check if it has the write property
        if characteristic.properties.contains(.writeWithoutResponse) && peripheral != nil {
            print("write char")
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        }
    }
    
    
    @IBAction func channelModif(_ sender: UISegmentedControl) {
        print("channel", sender.selectedSegmentIndex)
        progress = 1
        writeDSPchange(withCharacteristic: dspChar!, withValue: ("C\(sender.selectedSegmentIndex)").data(using: .utf8)!)
    }
    
    @IBAction func volumeModif(_ sender: UISlider) {
        print("volume", sender.value)
        progress = 1
        writeDSPchange(withCharacteristic: dspChar!, withValue: ("V\(Int(sender.value))").data(using: .utf8)!)
    }
    
    
    func modifWifi(){
        
        print("changing wifi alert")
        
        var ssid : String!
        var pass : String!
        var country : String!
        
        self.showInputDialog(title: "Ekoz-minidacdsp",
                             subtitle: "change wifi…",
                             actionTitle: "Next",
                             cancelTitle: "Cancel",
                             inputPlaceholder: "SSID",
                             inputText: "",
                             inputKeyboardType: .default,
                             actionHandler:
                                { (input:String?) in
                                    if input! != "" {
                                        ssid = input
                                        
                                        self.showInputDialog(title: "Ekoz-minidacdsp",
                                                             subtitle: "change wifi…",
                                                             actionTitle: "Next",
                                                             cancelTitle: "Cancel",
                                                             inputPlaceholder: "Password",
                                                             inputText: "",
                                                             inputKeyboardType: .default,
                                                             actionHandler:
                                                                { (input:String?) in
                                                                    if input! != "" {
                                                                        pass = input
                                                                        
                                                                        self.showInputDialog(title: "Ekoz-minidacdsp",
                                                                                             subtitle: "change wifi…",
                                                                                             actionTitle: "Change",
                                                                                             cancelTitle: "Cancel",
                                                                                             inputPlaceholder: "Country (US,FR…)",
                                                                                             inputText: "",
                                                                                             inputKeyboardType: .default,
                                                                                             actionHandler:
                                                                                                { (input:String?) in
                                                                                                    if input! != "" && input?.count ?? 0 > 1  {
                                                                                                        country = input
                                                                                                        
                                                                                                        self.modifWifiCred(ssid: ssid, pass: pass, country: country)
                                                                                                        
                                                                                                    }
                                                                                                })
                                                                    }
                                                                })
                                        
                                        
                                    }
                                })
    }
    
    func modifWifiCred(ssid:String, pass:String, country:String){
        
        //        let string = "FR&&&Livebox-BB0C&&&4YFw3G6qh3Ztwk49nF"
        
        let startIndex = country.index(country.startIndex, offsetBy: 2)
        let country2 = String(country[..<startIndex])    // "My "
        
        
        let string = "&\(country2.uppercased())&&&\(ssid)&&&\(pass)"
        print(string)
        self.writeDSPchange(withCharacteristic: self.wifiChar!, withValue: string.data(using: .utf8)!)
        
        showAlert(withTitle: "Ekoz-minidacdsp", withMessage: "Restarting new wifi…")
        
        
        
    }
    
    
    
    
    
    func showAlert(withTitle title: String, withMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
    }
    
    
    func showInputDialog(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Ajouter",
                         cancelTitle:String? = "Annuler",
                         inputPlaceholder:String? = nil,
                         inputText:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.text =  inputText
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "options"{
            
            if let optionsVC = segue.destination as? OptionsViewController{
                
                optionsVC.isWifi = isWifi
                optionsVC.isBluetooth = isBluetooth
                
                let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                
                optionsVC.versionStr = "Version: \(bundleVersion ?? "_") - Server: \(version.dropFirst()) - Temp: \(temperature)°C"
                
                optionsVC.callback = { result in
                    switch result {
                    case "shut":
                        self.writeDSPchange(withCharacteristic: self.sysChar!, withValue: String(2).data(using: .utf8)!)
//                    case "reboot":
//                        self.writeDSPchange(withCharacteristic: self.sysChar!, withValue: String(1).data(using: .utf8)!)
                    case "reset":
                        self.writeDSPchange(withCharacteristic: self.dspChar!, withValue: ("R").data(using: .utf8)!)
                        self.progress = 1
                    case "wifi":
                        self.writeDSPchange(withCharacteristic: self.wifiChar!, withValue: ("W").data(using: .utf8)!)
                        print("toggle wifi")
                    case "wifi2":
                        self.dismiss(animated: true, completion: nil)
                        self.modifWifi()
                        print("changing wifi")
                    case "bluetooth":
                        self.writeDSPchange(withCharacteristic: self.wifiChar!, withValue: ("B").data(using: .utf8)!)
                        print("toggle bluetooth")
                        
                        self.centralManager = nil
                        
                        self.showAlert(withTitle: "Pairing bluetooth", withMessage: "close this application\ngo to pref panel / bluetooth\nand pair your phone with \"ekoz-minidacdsp\"")
                        
                    case "bluetooth2":
                  
                        self.writeDSPchange(withCharacteristic: self.wifiChar!, withValue: ("R").data(using: .utf8)!)
                        print("reset Bluetooth")
                    default: break
                    }
                }
            }
            
        }
    }
}

