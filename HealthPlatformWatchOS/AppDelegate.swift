
import Foundation
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    var healthDataManager = HealthDataManager()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var backgroundTask = UIBackgroundTaskIdentifier.invalid
        backgroundTask = application.beginBackgroundTask(withName: "SendData") {
            if (self.healthDataManager.connectionStatus != "Connected") {
                print(self.healthDataManager.connectionStatus)
                self.healthDataManager.mqttClient = AWSViewModel()
            }
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                if self.healthDataManager.connectionStatus == "Connected" {
                    print("yes")
                    self.healthDataManager.queryHeartRateData()
                    self.healthDataManager.queryHRVData()
                    completionHandler(.newData)
                    timer.invalidate()
                }
            }
            application.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }
    //        let seconds = 5.0
    //        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
    //
    //        }
    
    //    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    //        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.UBC-CIC.HealthPlatformWatchOS.HealthDataManager.QueryHeartRateData", using: nil) { task in
    //            self.handleAppRefresh(task: task as! BGAppRefreshTask)
    //        }
    //    }
    //
    //    func scheduleAppRefresh() {
    //       let request = BGAppRefreshTaskRequest(identifier: "com.UBC-CIC.HealthPlatformWatchOS.HealthDataManager.QueryHeartRateData")
    //       request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
    //
    //       do {
    //          try BGTaskScheduler.shared.submit(request)
    //       } catch {
    //          print("Could not schedule app refresh: \(error)")
    //       }
    //    }
    //
    //    func handleAppRefresh(task: BGAppRefreshTask) {
    //        task.expirationHandler = {
    //            task.setTaskCompleted(success: false)
    //        }
    //        print(Int.random(in: 0..<100))
    //        task.setTaskCompleted(success: true)
    //       // Schedule a new refresh task.
    //       scheduleAppRefresh()
    //     }
}
