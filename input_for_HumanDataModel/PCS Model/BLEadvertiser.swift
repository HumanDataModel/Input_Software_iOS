import UIKit
import CoreLocation
import CoreBluetooth

class BLEadvertiser: NSObject, CBPeripheralManagerDelegate {
    
    var peripheralManager : CBPeripheralManager?
    
    /* A newly-generated UUID for our beacon */
    let BEACON_UUID : CBUUID
    let DEVICE_IDENTITY : String
    
    /* The identifier of our beacon is the identifier of our bundle here */
    //let identifier = Bundle.mainBundle.bundleIdentifier!
    
    /* Made up major and minor versions of our beacon region */
    let major: CLBeaconMajorValue = 1
    let minor: CLBeaconMinorValue = 0
    
    
    init(serviceUUID : String, deviceIdentity : String) {
        self.BEACON_UUID = CBUUID(string: serviceUUID)
        self.DEVICE_IDENTITY = deviceIdentity
    }
    
    
    func peripheralManagerDidStartAdvertising(_ peripheral:CBPeripheralManager, error: Error?){
        
        if error == nil {
            print("Successfully started advertising our beacon data")
            
        } else {
            print("Failed to advertise our beacon. Error = \(error)")
        }
        
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager){
        
        peripheral.stopAdvertising()
        
        /* Bluetooth is now powered on */
        if peripheral.state != .poweredOn{
            print("Bluetooth Not On!")
        } else {
            
            
            let theUUid = [BEACON_UUID]
            
            let dataToBeAdvertised:[String: AnyObject] = [
                CBAdvertisementDataLocalNameKey : self.DEVICE_IDENTITY as AnyObject,
                CBAdvertisementDataServiceUUIDsKey : theUUid as AnyObject,
                ]
            
            peripheral.startAdvertising(dataToBeAdvertised)
            
            print("Now Advertising BLE with: " + BEACON_UUID.uuidString)
            
        }
        
    }
    
    public func beginToAdvertise() {
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
}
