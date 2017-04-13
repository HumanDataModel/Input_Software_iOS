//
//  ViewController.swift
//  PCS Model
//
//  Created by Niko Mäkitalo on 19.1.2017.
//  Copyright © 2017 Niko Mäkitalo. All rights reserved.
//

import Intents

import UIKit

import FBSDKCoreKit
import FBSDKLoginKit

import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var deviceIdentity = "alice@iphone"
    let host = "orchestratorjs.org"
    let port = "9006"
    
    // Facebook
    var facebookInfo: NSMutableDictionary
    var facebookFriends: NSMutableDictionary
    
    
    // GPS
    let GPS_MEASUREMENT_INTERVAL = 1  // How long waits until next measurement
    
    @IBOutlet var sendGPSSwitch: UISwitch!
    let locationManager = CLLocationManager()
    
    
    
    // BLE
    
    let BLE_MEASUREMENT_TIME     = 1  // How long measures
    let BLE_MEASUREMENT_INTERVAL = 1  // How long waits until next measurement
    
    @IBOutlet var sendBLESwitch: UISwitch!
    var BEAN_SERVICE_UUID = "a495ff20-c5b1-4b44-b512-1370f02d74de"
    
    var bleDatasource: BLEdatasource
    
    var advertiser: BLEadvertiser

    
    
    var socket: SocketIOClient
    
    
    
    
    
    required init?(coder aDecoder: NSCoder) {
        
        let modelName = UIDevice.current.modelName
        print(modelName)
        
        if(modelName == "iPhone SE") {
            deviceIdentity = "bob@iphoneSE"
            BEAN_SERVICE_UUID = "5bf2e050-4730-46de-b6a7-2c8be4d9fa36"
        } else if(modelName == "iPhone 7 Plus") {
            deviceIdentity = "alice@iphone"
            BEAN_SERVICE_UUID = "717f860e-f0e6-4c93-a4e3-cc724d27e05e"
        } else if(modelName == "iPhone 5") {
            deviceIdentity = "nkm@iphone5"
            BEAN_SERVICE_UUID = "717f860e-f0e6-4c93-a4e3-cc724d27e05b"
        } else {
            print("unknown device")
        }
        
        
        socket = SocketIOClient(socketURL: NSURL(string: "http://"+host+":"+port) as! URL);
        socket.on("connect") {data, ack in
            print("Socket.IO connected")
        }
        socket.connect()
        
        
        ///// Facebook
        
        facebookInfo = NSMutableDictionary()
        facebookFriends = NSMutableDictionary()
        
        
        ///// BLE
        
        
        
        self.bleDatasource = BLEdatasource(socket_emit: socket.emit, serviceUUID: BEAN_SERVICE_UUID, deviceIdentity: deviceIdentity)
        
                
        // BLE advertising
        self.advertiser = BLEadvertiser(serviceUUID: BEAN_SERVICE_UUID, deviceIdentity: deviceIdentity)
        self.advertiser.beginToAdvertise()

        
        super.init(coder: aDecoder)
        
        
        
        ///// GPS
        
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile","user_friends"] //["user_friends", "user_likes"]
        
        loginButton.center = self.view.center
        
        self.view.addSubview(loginButton)
        
        
        INPreferences.requestSiriAuthorization() { (status) in
            print("New status: \(status)")
        }
        
    }
    
    
    func sendPCSdata(_ key: String, data: Any) {
        let pcs_data = NSMutableDictionary();
        pcs_data.setObject(data, forKey: key as NSCopying)
        socket.emit("data", with: [self.deviceIdentity, pcs_data])
    }
    
    
    
    @IBAction func sendOwnFBDataAction(_ sender: AnyObject) {
        print(self.facebookInfo)
        sendPCSdata("facebook_profile", data: facebookInfo)
    }
    
    @IBAction func sendFBFriendsDataAction(_ sender: AnyObject) {
        print(self.facebookFriends)
        sendPCSdata("facebook_friends", data: facebookFriends)
    }
    
    @IBAction func facebookAction(_ sender: AnyObject) {
        
        if((FBSDKAccessToken.current()) != nil) {
            
            if(FBSDKAccessToken.current().hasGranted("user_friends")) {
                
                let fbgr : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, friends"])
                
                fbgr.start(completionHandler: { (connection, result, error) -> Void in
                    if(error == nil && result != nil) {
                        
                        let facebookData = result as! NSDictionary
                        
                        print(facebookData)
                        
                        let ownFacebookName = (facebookData.object(forKey: "name") as! String)
                        let ownFacebookID = (facebookData.object(forKey: "id") as! String)
                        
                        print(ownFacebookName)
                        print(ownFacebookID)
                        
                        self.facebookInfo.setValue(ownFacebookName, forKey: "name")
                        self.facebookInfo.setValue(ownFacebookID, forKey: "id")
                        
                        let fbid = facebookData.value(forKey: "id") as! String
                        print(fbid)
                        
                        
                        let data = (facebookData.object(forKey: "friends") as! NSDictionary)
                        let facebookFriendsData = (data.object(forKey: "data") as! NSArray)
                        
                        self.facebookFriends = NSMutableDictionary();
                        for row in facebookFriendsData {
                            let r = row as! NSDictionary
                            let name = r.value(forKey: "name") as! String
                            let fbid = r.value(forKey: "id") as! String
                            
                            print(name)
                            print(fbid)
                            
                            self.facebookFriends.setValue(name, forKey: fbid)
                        }
                    }
                })
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(sendGPSSwitch.isOn) {
            let locValue:CLLocationCoordinate2D = manager.location!.coordinate
            print("locations = \(locValue.latitude) \(locValue.longitude)")
            let coordinates = NSMutableDictionary()
            coordinates.setValue(locValue.latitude, forKey: "latitude")
            coordinates.setValue(locValue.longitude, forKey: "longitude")
            sendPCSdata("gps_coordinates", data: coordinates)
        }
    }
    
    
    /// BLE
    @available(iOS 10.0, *)
    @IBAction func sendBLESliderAction(sender: UISlider) {
        print("toggle")
        
        if(sender.value > 0) {
            print("on")
            print(sender.value)
            bleDatasource.BLE_MEASUREMENT_INTERVAL = Int(sender.value)
            bleDatasource.scan()
            
        } else {
            print("off")
            bleDatasource.stop()
        }
    }
    
    
}
