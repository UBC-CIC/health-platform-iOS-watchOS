
import Foundation
import HealthKit
import WatchConnectivity

class HealthDataManager: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var deviceID = "N/A"
    @Published var heartRate : Double = 0
    @Published var heartRateVariability : Double = 0
    var session = WCSession.default
    let mqttClient = AWSViewModel()
    let healthStore = HKHealthStore()
   
    //Enable data sending from watch to phone via bluetooth
    func setupSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    //Recieve data message from watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["deviceID"] != nil && message["heartRate"] != nil {
            print("RECIEVED HR: \(String(describing: message["heartRate"]))")
            DispatchQueue.main.async {
                self.deviceID = message["deviceID"] as! String
                if (message["heartRate"] as! Double != 0) {
                    self.heartRate = message["heartRate"] as! Double
                    self.sendDataToAWS(measurement: self.heartRate, measurementType: "HeartRate")
                }
                self.queryHRVData()
            }
        } else {
            print("Did not receive heart rate =[")
        }
    }
    
    //WCSession activation state
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    //Query from HealthKit the latest HRV data within the last 24hrs
    func queryHRVData(){
        let HRVType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)

        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)

        let startDate = Date() - 24 * 60 * 60 // start date is 24hrs
        //  Set the Predicates & Interval
        let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: HKQueryOptions.strictEndDate)
        let sampleQuery = HKSampleQuery(sampleType: HRVType!, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { sampleQuery, results, error  in
            if(error == nil) {
                for result in (results as? [HKQuantitySample])! {
                    let latestHRV = result.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    if (self.heartRateVariability != latestHRV) {
                        DispatchQueue.main.async {
                            self.heartRateVariability = latestHRV
                            self.sendDataToAWS(measurement: self.heartRateVariability, measurementType: "HeartRateVariability")
                        }
                    }
                    break
                }
            }
        }
        healthStore.execute(sampleQuery)
    }
        
    func dataToJson(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    //Send data to IoT Endpoint
    func sendDataToAWS(measurement: Double, measurementType: String) {
        let date = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        
        let data: [String: Any] = [
            "sensorId": self.deviceID,
            "measurementType": measurementType,
            "measurement": String(measurement),
            "timestamp": formatter.string(from:date)
        ]
        
        let jsonDataString = dataToJson(from: data)
        if (jsonDataString != nil) {
            print("Published : \(String(describing: jsonDataString))")
        }
        mqttClient.publishMessage(message: jsonDataString)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
            print("sessionDidBecomeInactive: \(session)")
    }


    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate: \(session)")
        self.session.activate()
    }
}
