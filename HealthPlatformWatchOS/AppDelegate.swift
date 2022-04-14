
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    var healthDataManager = HealthDataManager()
    
    //Lock application orientation in portrait mode
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
    //Register the background refresh task and schedule task
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.UBCCIC.queryData",
          using: nil) { (task) in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        var scheduledTasks = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
                scheduledTasks = tasks.count
            })
            if (scheduledTasks == 0) {
                self.scheduleBackgroundDataSend()
            } else {
                timer.invalidate()
            }
        }
        return true
    }
    
    //Code to be executed when a background refresh is triggered
    func handleAppRefreshTask(task: BGAppRefreshTask) {
        //Triggers when the app refresh reaches 30 seconds of runtime
        task.expirationHandler = {
            self.healthDataManager.expirationReached()
            task.setTaskCompleted(success: false)
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
                print("Tasks", tasks.count, tasks);
            })
        }
        scheduleBackgroundDataSend()
        if (healthDataManager.connectionStatus != "Connected") {
            healthDataManager.mqttClient.connectToAWSIoT()
        }
        let connectionTimeoutLimit = Date().timeIntervalSince1970 + 28 //hard limit is a 30s
        var connectionTimeoutLimitReached = false
        while (healthDataManager.connectionStatus != "Connected") {
            if (Date().timeIntervalSince1970 >= connectionTimeoutLimit) {
                self.healthDataManager.expirationReached()
                connectionTimeoutLimitReached = true
                task.setTaskCompleted(success: false)
                break
            }
        }
        if (connectionTimeoutLimitReached == false) {
            healthDataManager.queryHeartRateData()
            healthDataManager.queryHRVData()
            task.setTaskCompleted(success: true)
        }
        BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
            print("Tasks", tasks.count, tasks);
        })
    }
    
    //Schedules the background app refresh
    func scheduleBackgroundDataSend() {
        let queryTask = BGAppRefreshTaskRequest(identifier: "com.UBCCIC.queryData")
        //Set the minimum background fetch interval in seconds. This interval is not an exact time interval of when each background fetch will be run. Setting the interval states that a background fetch will happen AT MOST once per X seconds, Apple has its own algorithm for scheduling the actual runtimes.
        queryTask.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(queryTask)
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
                print("Tasks", tasks.count, tasks);
            })
        } catch {
            print("Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    //Cancel all task requests when the app is force quit
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
