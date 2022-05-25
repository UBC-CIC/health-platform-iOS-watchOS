
import Foundation
import HealthKit
import UIKit
import BackgroundTasks
import SwiftUI

class HealthDataManager: NSObject, ObservableObject {
    //Published variables which are updated in the UI
    @Published var deviceID = UIDevice.current.identifierForVendor!.uuidString
    @Published var connectionStatus = "Not Connected"
    @Published var connectionStatusIcon = "xmark.icloud"
    @Published var connectionStatusIconColour = Color.red
    @Published var lastQueryTime = ""
    @Published var HRDataPointsSent = 0
    @Published var HRVDataPointsSent = 0
    @Published var remainingBGTasks = 0
    @Published var earliestBGTaskExecutionDate = ""
    @Published var error = ""
    //Initialize the MQTT client
    var mqttClient = AWSViewModel()
    //Initialize HealthKit Store
    let healthStore = HKHealthStore()
    //For storing user information required for next app launch
    let defaults = UserDefaults.standard
    //Timer for updating IoT connection status
    var timer = Timer()
    //Data array for data that needs to be sent to AWS
    var dataArray : [[String: Any]] = []
    
    //Set deviceID, set query time defaults, set connection status, and request HealthKit permissions.
    func setupSession() {
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                            HKObjectType.quantityType(forIdentifier: .heartRate)!,
                            HKObjectType.quantityType(forIdentifier: .stepCount)!,])

        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                print("Authorization failed")
            }
        }
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
        updateUIValues()
    }
    
    //Repeatedly check for connection status from the MQTT client and the status of Background Tasks
    func updateUIValues() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if (self.connectionStatus != self.mqttClient.connectionStatus) {
                DispatchQueue.main.async {
                    self.connectionStatus = self.mqttClient.connectionStatus
                    if (self.connectionStatus == "Connected") {
                        self.connectionStatusIcon = "checkmark.icloud"
                        self.connectionStatusIconColour = Color.green
                    } else if (self.connectionStatus == "Reconnecting" || self.connectionStatus == "Connecting") {
                        self.connectionStatusIcon = "arrow.clockwise.icloud"
                        self.connectionStatusIconColour = Color.yellow
                    } else {
                        self.connectionStatusIcon = "xmark.icloud"
                        self.connectionStatusIconColour = Color.red
                    }
                }
            }
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
                DispatchQueue.main.async {
                    if (tasks.count != 0) {
                        let bgTaskDate = tasks[0].earliestBeginDate ?? Date()
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: bgTaskDate)
                        let minutes = calendar.component(.minute, from: bgTaskDate)
                        let day = calendar.component(.day, from: bgTaskDate)
                        let month = calendar.component(.month, from: bgTaskDate)
                        let year = calendar.component(.year, from: bgTaskDate)
                        if (minutes < 10) {
                            self.earliestBGTaskExecutionDate = "\(month)-\(day)-\(year): \(hour):\(String(format: "%02d", minutes))"
                        } else {
                            self.earliestBGTaskExecutionDate = "\(month)-\(day)-\(year): \(hour):\(minutes)"
                        }
                    }
                    self.remainingBGTasks = tasks.count
                }
            })
        })
    }
    
    //For displaying errors in the UI. 0: no errors. -1: unable to connect to iot. -2: expiration handler reached. -3: bgTask could not be scheduled
    func expirationReached(expirationCode: String) {
        DispatchQueue.main.async {
            self.error = expirationCode
        }
    }
    
    //Query from HealthKit the latest HRV values since the last query, default query is from the first time you open the app
    func queryHRVData(){
        let HRVType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)

        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        //Get unrecorded time from from current query time minus the last query time, and set record new times in user defaults
        var startDate: Date
        let lastQueryTime = defaults.double(forKey: "lastHRVQueryTime")
        let currentTime  = Date().timeIntervalSince1970
        let timeDifference = currentTime - lastQueryTime
        startDate = Date() - timeDifference
        
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
                        self.defaults.set(result.endDate.timeIntervalSince1970, forKey: "lastHRVQueryTime")
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
                    let data: [String: Any] = [
                        "measurementType": "HeartRateVariability",
                        "measurement": resultStringData,
                        "timestamp": resultStringTimestamps
                    ]
                    self.dataArray.append(data)
                }
            }
        }
        healthStore.execute(sampleQuery)
    }
    
    //Query from HealthKit the latest Heart Rate values since the last query, default query is from the first time you open the app
    func queryHeartRateData() {
        let HRType = HKQuantityType.quantityType(forIdentifier: .heartRate)

        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        //Get unrecorded time from from current query time minus the last query time, and set record new times in user defaults
        var startDate: Date
        let lastQueryTime = defaults.double(forKey: "lastHRQueryTime")
        let currentTime  = Date().timeIntervalSince1970
        let timeDifference = currentTime - lastQueryTime
        startDate = Date() - timeDifference
        
        //  Set the Predicates & Interval
        let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: HKQueryOptions.strictEndDate)
        let sampleQuery = HKSampleQuery(sampleType: HRType!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { sampleQuery, results, error  in
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
                        self.defaults.set(result.endDate.timeIntervalSince1970, forKey: "lastHRQueryTime")
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
                    let data: [String: Any] = [
                        "measurementType": "HeartRate",
                        "measurement": resultStringData,
                        "timestamp": resultStringTimestamps
                    ]
                    self.dataArray.append(data)
                }
            }
        }
        healthStore.execute(sampleQuery)
    }
    
    func queryStepsData() {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepsQuantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            let stepsValue = sum.doubleValue(for: HKUnit.count())
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions.insert(.withFractionalSeconds)
            let timestamp = formatter.string(from: Date())
            if (stepsValue > 0) {
                let data: [String: Any] = [
                    "measurementType": "Steps",
                    "measurement": String(stepsValue),
                    "timestamp": timestamp
                ]
                self.dataArray.append(data)
            }
        }
        healthStore.execute(query)
    }
    
    //Convert string array to JSON
    func dataToJson(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    //Send data to IoT Endpoint for UI button
    func sendDataToAWSButton() {
        queryHeartRateData()
        queryHRVData()
        queryStepsData()
        //slight delay required to ensure healthkit queries complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if (self.dataArray.isEmpty == false) {
                let data: [String: Any] = [
                    "sensorId": self.deviceID,
                    "data": self.dataArray
                ]
                let jsonDataString = self.dataToJson(from: data)
                if (jsonDataString != nil) {
                    print("Published : \(String(describing: jsonDataString))")
                }
                self.dataArray.removeAll()
                self.mqttClient.publishMessage(message: jsonDataString)
            }
        }
    }
    
    //Send data to IoT Endpoint for BGTask
    func sendDataToAWSBGTask() {
        timer.invalidate()
        queryHeartRateData()
        queryHRVData()
        queryStepsData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if (self.dataArray.isEmpty == false) {
                let data: [String: Any] = [
                    "sensorId": self.deviceID,
                    "data": self.dataArray
                ]
                let jsonDataString = self.dataToJson(from: data)
                self.dataArray.removeAll()
//                if (jsonDataString != nil) {
//                    print("Published : \(String(describing: jsonDataString))")
//                }
                self.mqttClient.publishMessage(message: jsonDataString)
            }
        }
    }
}
