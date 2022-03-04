/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file contains the business logic, which is the interface to HealthKit.
*/

import Foundation
import HealthKit
import Combine
import WatchKit
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate {
    
    /// - Tag: DeclareSessionBuilder
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
    var watchSession = WCSession.default
    
    /// - Tag: Publishers
    @Published var heartrate: Double = 0
    @Published var elapsedSeconds: Int = 0
    
    @IBOutlet weak var labelX: WKInterfaceLabel!
    @IBOutlet weak var labelY: WKInterfaceLabel!
    @IBOutlet weak var labelZ: WKInterfaceLabel!
    
    // The app's workout state.
    var running: Bool = false
    
    /// - Tag: TimerSetup
    // The cancellable holds the timer publisher.
    var start: Date = Date()
    var cancellable: Cancellable?
    var accumulatedTime: Int = 0
    
    let userDefaults = UserDefaults()
    var clientID: String?
    var deviceID: String = ""
    var deviceIDFirst: String = ""
    var deviceIDSecond: String = ""
    var lastUpdateTime: Int = 0
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Activation State: \(activationState), Error: \(String(describing: error)))")
    }
    
    // Set up and start the timer.
    func setUpTimer() {
        start = Date()
        cancellable = Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedSeconds = self.incrementElapsedTime()
            }
    }
    
    // Calculate the elapsed time.
    func incrementElapsedTime() -> Int {
        let runningTime: Int = Int(-1 * (self.start.timeIntervalSinceNow))
        return self.accumulatedTime + runningTime
    }
    

    // Request authorization to access HealthKit and start the watch session
    func requestAuthorization() {
        clientID = userDefaults.string(forKey: "deviceID")
        if(clientID == nil){
            clientID = WKInterfaceDevice.current().identifierForVendor?.uuidString
            userDefaults.set(clientID, forKey: "deviceID")
        }
        deviceID = WKInterfaceDevice.current().identifierForVendor!.uuidString
        deviceIDFirst = deviceID.substring(to: deviceID.index(deviceID.startIndex, offsetBy: 19))
        deviceIDSecond = deviceID.substring(from: deviceID.index(deviceID.startIndex, offsetBy: 19))
        
        if WCSession.isSupported() {
                watchSession.delegate = self
                watchSession.activate()
        }
        
        log(logMessage: "setup finished")
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKSeriesType.heartbeat(),
        ]
        
        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }

    
    // Provide the workout configuration.
    func workoutConfiguration() -> HKWorkoutConfiguration {
        /// - Tag: WorkoutConfiguration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        return configuration
    }
    
    func queryHeartBeatData() {
        let timeframe = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60 * 60 * 24), end: Date(), options: [])
        let heartbeatSeriesSampleQuery = HKSampleQuery(sampleType: HKSeriesType.heartbeat(), predicate: timeframe, limit: 20, sortDescriptors: nil) { (sampleQuery, samples, error) in
            if let heartbeatSeriesSample = samples?.first as? HKHeartbeatSeriesSample {
                let query = HKHeartbeatSeriesQuery(heartbeatSeries: heartbeatSeriesSample) { (query, timeSinceSeriesStart, precededByGap, done, error) in
                    print(timeSinceSeriesStart)
                }
                self.healthStore.execute(query)
            } else {
                print("ERROR")
            }
        }
        healthStore.execute(heartbeatSeriesSampleQuery)
}
    
    // Start the workout.
    func startWorkout() {
        // Start the timer.
        
        setUpTimer()
        self.running = true
        
        // Create the session and obtain the workout builder.
        /// - Tag: CreateWorkout
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: self.workoutConfiguration())
            builder = session.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            return
        }
        
        // Setup session and builder.
        session.delegate = self
        builder.delegate = self
        
        // Set the workout builder's data source.
        /// - Tag: SetDataSource
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: workoutConfiguration())
        
        // Start the workout session and begin data collection.
        /// - Tag: StartSession
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in
            // The workout has started.
        }
    }
    
    // MARK: - State Control
    func togglePause() {
        // If you have a timer, then the workout is in progress, so pause it.
        if running == true {
            self.pauseWorkout()
        } else {// if session.state == .paused { // Otherwise, resume the workout.
            resumeWorkout()
        }
    }
    
    func pauseWorkout() {
        // Pause the workout.
        session.pause()
        // Stop the timer.
        cancellable?.cancel()
        // Save the elapsed time.
        accumulatedTime = elapsedSeconds
        running = false
    }
    
    func resumeWorkout() {
        // Resume the workout.
        session.resume()
        // Start the timer.
        setUpTimer()
        running = true
    }
    
    func endWorkout() {
        // End the workout session.
        session.end()
        cancellable?.cancel()
    }
    
    func resetWorkout() {
        // Reset the published values.
        DispatchQueue.main.async {
            self.elapsedSeconds = 0
            self.heartrate = 0
        }
    }

    func getISOString() -> String {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sss"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let iso8601String = dateFormatter.string(from: Date()) + "Z"
        return iso8601String
    }
    
    func getOSVersion() -> String {
        let os = ProcessInfo().operatingSystemVersion
        return "watchOS " + String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    func sendDataToPhone(HR: Double, HRV: Double) {
        if (watchSession.isReachable) {
            watchSession.sendMessage(["deviceID": clientID, "heartRate" : heartrate], replyHandler: nil) { (error) in
                print("Error sending data: \(error.localizedDescription)")
            }
            print("SENT")
        } else {
            print("Iphone session not available")
        }
    }
    
    // MARK: - Update the UI
    // Update the published values.
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        let currentTime = Int(Date().timeIntervalSince1970)
        log(logMessage: String(currentTime))
        if(currentTime > lastUpdateTime + 10){
            lastUpdateTime = currentTime
            //sendDataToPhone(HR: heartrate, HRV: heartRateVariability)
            //queryHeartBeatData
        }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                /// - Tag: SetLabel
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                self.heartrate = roundedValue
                self.sendDataToPhone(HR: self.heartrate, HRV: 0)
            case HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN):
                return
            default:
                return
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        // Wait for the session to transition states before ending the builder.
        /// - Tag: SaveWorkout
        if toState == .ended {
            print("The workout has now ended.")
            builder.endCollection(withEnd: Date()) { (success, error) in
                self.builder.finishWorkout { (workout, error) in
                    // Optionally display a workout summary to the user.
                    self.resetWorkout()
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

func log(logMessage: String, functionName: String = #function) {
    print("\(functionName): \(logMessage)")
}


// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            /// - Tag: GetStatistics
            let statistics = workoutBuilder.statistics(for: quantityType)
            //log(logMessage: "here")
            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}
