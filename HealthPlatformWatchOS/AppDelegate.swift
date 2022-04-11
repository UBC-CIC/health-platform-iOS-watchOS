
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    var healthDataManager = HealthDataManager()
    
//    Lock application orientation in portrait mode
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.UBCCIC.queryData",
          using: nil) { (task) in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        scheduleBackgroundDataSend()
        return true
    }
    
    func handleAppRefreshTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            DispatchQueue.global(qos: .background).sync {
                task.setTaskCompleted(success: false)
            }
        }
        DispatchQueue.global(qos: .background).sync {
            scheduleBackgroundDataSend()
            if (healthDataManager.connectionStatus != "Connected") {
                healthDataManager.mqttClient.connectToAWSIoT()
            }
            while (healthDataManager.connectionStatus != "Connected") {
                //wait for a connection, timeout is after 30s when the expiration handler will be called
            }
            healthDataManager.queryHeartRateData()
            healthDataManager.queryHRVData()
            task.setTaskCompleted(success: true)
        }
    }
    
    func scheduleBackgroundDataSend() {
        DispatchQueue.global(qos: .background).sync {
            let queryTask = BGAppRefreshTaskRequest(identifier: "com.UBCCIC.queryData")
            queryTask.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
            do {
                try BGTaskScheduler.shared.submit(queryTask)
            } catch {
                print("Unable to submit task: \(error.localizedDescription)")
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    //    //Set the minimum background fetch interval in seconds. This interval is not an exact time interval of when each background fetch will be run. Setting the interval states that a background fetch will happen AT MOST once per X seconds, Apple determines the actual runtimes.
    //    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    //        DispatchQueue.global(qos: .background).sync {
    //            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    //            healthDataManager.yes()
    //            return true
    //        }
    //    }
    //
    //    //Execute HealthKit Query and send to IoT synchonously on the background thread after verifying there is a connection to IoT. If this cannot be completed within the seconds specified by connectionTimeoutLimit, the background fetch will fail.
    //    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    //        DispatchQueue.global(qos: .background).sync {
    //            var connectionTimeoutCount = 0
    //            let connectionTimeoutLimit = 25 //Hard limit for a background fetch is 30s
    //            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
    //                connectionTimeoutCount += 1
    //                if self.healthDataManager.connectionStatus == "Connected" {
    //                    self.healthDataManager.queryHeartRateData()
    //                    self.healthDataManager.queryHRVData()
    //                    completionHandler(.newData)
    //                    timer.invalidate()
    //                } else if connectionTimeoutCount == connectionTimeoutLimit {
    //                    self.healthDataManager.yes()
    //                    completionHandler(.failed)
    //                    timer.invalidate()
    //                }
    //            }
    //        }
    //    }
}
