//
//  BLEdata.swift
//  PCSdata
//
//  Created by Niko Mäkitalo on 13.12.2016.
//  Copyright © 2016 Niko Mäkitalo. All rights reserved.
//

import Foundation
import CoreBluetooth


class BLEdatasource: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    // TODO: use half of the interval for each of these
    var BLE_MEASUREMENT_TIME     = 1  // How long measures
    var BLE_MEASUREMENT_INTERVAL = 1  // How long waits until next measurement
    
    var manager:CBCentralManager!
    
    var scanningOn: Bool
    
    let BEAN_NAME: String
    let BEAN_SERVICE_UUID: CBUUID
    
    var currentFoundBLEs: Dictionary<String, Array<Int>>
    
    let dispatcher: (String, [Any]) -> ()
    
    
    init(socket_emit: @escaping (String, [Any]) -> (), serviceUUID: String, deviceIdentity: String) {
        
        self.BEAN_SERVICE_UUID = CBUUID(string: serviceUUID)
        self.BEAN_NAME = deviceIdentity
        
        self.scanningOn = false
        self.currentFoundBLEs = Dictionary()
        
        self.dispatcher = socket_emit
        
    }
    
    
    
    @available(iOS 10.0, *)
    public
    func scan() {
        self.scanningOn = true
        self.intervalScan()
    }
    
    public
    func stop() {
        self.scanningOn = false
        self.stopScan()
    }
    
    
    
    
    
    @available(iOS 10.0, *)
    private
    func intervalScan() {
        
        if(self.scanningOn) {
            
            // Scan for the developer defined time
            startScan()
            
            Timer.scheduledTimer(withTimeInterval: TimeInterval(self.BLE_MEASUREMENT_TIME), repeats: false, block: { (timer:Timer) in
                
                self.stopScan()
                
                // report data to server
                self.reportData()
                
                // wait developer defined interval and then call self
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.BLE_MEASUREMENT_INTERVAL), execute: {
                    self.intervalScan()
                })
            })
            
        } else {
            print("scanning off")
        }
    }
    
    
    
    
    
    private
    func reportData() {
        
        print("Sending to server")
        let results = getAverageRSSIs()
        
        let pcs_data = NSMutableDictionary();
        pcs_data.setObject(results, forKey: "ble_devices" as NSCopying)
        
        dispatcher("data", [BEAN_NAME, pcs_data])
        
        self.currentFoundBLEs = Dictionary()

    }
    
    
    private
    func stopScan() {
        if self.manager != nil && self.manager.isScanning {
            self.manager.stopScan()
            self.manager = nil
        }
    }
    
    private
    func startScan() {
        self.stopScan()
        if(self.scanningOn) {
            self.manager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    internal
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is available.")
            central.scanForPeripherals(withServices: nil, options: nil)
        default:
            print("Bluetooth not available.")
        }
    }
    
    internal
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let list = advertisementData["kCBAdvDataServiceUUIDs"] as? [AnyObject] {
            if(!list.isEmpty) {
                let v = list[0]
                let serviceUUID = v as! CBUUID
                print("Service UUID: " + serviceUUID.uuidString + " with RSSI: " + RSSI.stringValue)
                saveMeasurement(serviceUUID: serviceUUID.uuidString, rssi: RSSI.intValue)
            }
        }
    }
    
    internal
    func saveMeasurement(serviceUUID: String, rssi: Int) {
        if self.currentFoundBLEs[serviceUUID] == nil {
            self.currentFoundBLEs[serviceUUID] = Array()
        }
        self.currentFoundBLEs[serviceUUID]?.append(rssi)
    }
    
    
    internal
    func getAverageRSSIs() -> Dictionary<String, Double> {
        var results = Dictionary<String, Double>()
        for measurements in self.currentFoundBLEs {
            let rssiAvg = Double(measurements.value.reduce(0, +)) / Double(measurements.value.count)
            results[measurements.key] = rssiAvg
        }
        return results
    }
    
    
    // save for later
    //let votesAvg = votes.reduce(0, combine: +) / Double(votes.count)
    

    
}
