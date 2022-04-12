
import Foundation
import HealthKit
import UIKit

class HealthDataManager: NSObject, ObservableObject {
    //Published variables which are updated in the UI
    @Published var deviceID = UIDevice.current.identifierForVendor!.uuidString
    @Published var connectionStatus = "Not Connected"
    @Published var lastQueryTime = ""
    @Published var HRDataPointsSent = 0
    @Published var HRVDataPointsSent = 0
    //Initialize the MQTT client
    var mqttClient = AWSViewModel()
    //Initialize HealthKit Store
    let healthStore = HKHealthStore()
    //For storing user information required for next app launch
    let defaults = UserDefaults.standard
    //Timer for updating IoT connection status
    var timer = Timer()
    
    //Set deviceID, query time defaults, and set connection status.
    func setupSession() {
        if defaults.string(forKey: "isHRSet") == nil {
            defaults.set((Int(Date().timeIntervalSince1970)), forKey: "lastHRQueryTime")
            defaults.set("Yes", forKey: "isHRSet")
        }
        if defaults.string(forKey: "isHRVSet") == nil {
            defaults.set((Int(Date().timeIntervalSince1970)), forKey: "lastHRVQueryTime")
            defaults.set("Yes", forKey: "isHRVSet")
        }
        DispatchQueue.main.async {
            self.lastQueryTime = self.defaults.string(forKey: "lastQueryTime") ?? "Never Queried"
        }
        updateConnectionStatus()
    }
    
    //Repeatedly check for connection status from the MQTT client
    func updateConnectionStatus() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                DispatchQueue.main.async {
                    self.connectionStatus = self.mqttClient.connectionStatus
                
            }
        })
    }

    //Query from HealthKit the latest HRV values since the last query, default query is from the first time you open the app
    func queryHRVData(){
        let HRVType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)

        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        //Get unrecorded time from from current query time minus the last query time, and set record new times in user defaults
        var startDate: Date
        let lastQueryTime = defaults.integer(forKey: "lastHRVQueryTime")
        let currentTime  = (Int)(Date().timeIntervalSince1970)
        let timeDifference = Double(currentTime - lastQueryTime)
        startDate = Date() - timeDifference
        defaults.set(currentTime, forKey: "lastHRVQueryTime")
        
        //  Set the Predicates & Interval
        let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: HKQueryOptions.strictEndDate)
        let sampleQuery = HKSampleQuery(sampleType: HRVType!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { sampleQuery, results, error  in
            if(error == nil) {
                var count = 0
                var resultStringData = ""
                var resultStringTimestamps = ""
                for result in (results as? [HKQuantitySample])! {
                    let latestHRV = result.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions.insert(.withFractionalSeconds)
                    if (count == 0) {
                        resultStringData = String(round(latestHRV))
                        resultStringTimestamps = formatter.string(from:(result.endDate))
                    } else {
                        resultStringData = resultStringData + ", " + String(latestHRV)
                        resultStringTimestamps = resultStringTimestamps + ", " + formatter.string(from:(result.endDate))
                    }
                    
                    count += 1
                }
                DispatchQueue.main.async {
                    self.HRVDataPointsSent = count
                }
                if (count > 0) {
                    self.sendDataToAWS(measurements: resultStringData, measurementType: "HeartRateVariability", timestamps: resultStringTimestamps)
                }
            }
        }
        healthStore.execute(sampleQuery)
    }
    
    //Query from HealthKit the latest Heart Rate values since the last query, default query is from the first time you open the app
    func queryHeartRateData() {
        let HRVType = HKQuantityType.quantityType(forIdentifier: .heartRate)

        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        //Get unrecorded time from from current query time minus the last query time, and set record new times in user defaults
        var startDate: Date
        let lastQueryTime = defaults.integer(forKey: "lastHRQueryTime")
        let currentTime  = (Int)(Date().timeIntervalSince1970)
        let timeDifference = Double(currentTime - lastQueryTime)
        startDate = Date() - timeDifference
        defaults.set(currentTime, forKey: "lastHRQueryTime")
        
        //  Set the Predicates & Interval
        let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: HKQueryOptions.strictEndDate)
        let sampleQuery = HKSampleQuery(sampleType: HRVType!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { sampleQuery, results, error  in
            if(error == nil) {
                var count = 0
                var resultStringData = ""
                var resultStringTimestamps = ""
                for result in (results as? [HKQuantitySample])! {
                    let latestHeartRate = result.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions.insert(.withFractionalSeconds)
                    if (count == 0) {
                        resultStringData = String(round(latestHeartRate))
                        resultStringTimestamps = formatter.string(from:(result.endDate))
                    } else {
                        resultStringData = resultStringData + ", " + String(latestHeartRate)
                        resultStringTimestamps = resultStringTimestamps + ", " + formatter.string(from:(result.endDate))
                    }
                    
                    count += 1
                }
                //Update the latest query time for the UI
                let date = Date()
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: date)
                let minutes = calendar.component(.minute, from: date)
                let day = calendar.component(.day, from: date)
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                if (minutes < 10) {
                    self.defaults.set("\(month)-\(day)-\(year): \(hour):\(String(format: "%02d", minutes))", forKey: "lastQueryTime")
                } else {
                    self.defaults.set("\(month)-\(day)-\(year): \(hour):\(minutes)", forKey: "lastQueryTime")
                }
                
                DispatchQueue.main.async {
                    self.lastQueryTime = self.defaults.string(forKey: "lastQueryTime") ?? "Never Queried"
                    self.HRDataPointsSent = count
                }
                if (count > 0) {
                    self.sendDataToAWS(measurements: resultStringData, measurementType: "HeartRate", timestamps: resultStringTimestamps)
                }
            }
        }
        healthStore.execute(sampleQuery)
    }
    
    //Convert string array to JSON
    func dataToJson(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    //Send data to IoT Endpoint
    func sendDataToAWS(measurements: String, measurementType: String, timestamps: String) {
        
        let data: [String: Any] = [
            "sensorId": self.deviceID,
            "measurementType": measurementType,
            "measurement": measurements,
            "timestamp": timestamps
        ]
        
        let jsonDataString = dataToJson(from: data)
        if (jsonDataString != nil) {
            print("Published : \(String(describing: jsonDataString))")
        }
        mqttClient.publishMessage(message: jsonDataString)
    }
}
