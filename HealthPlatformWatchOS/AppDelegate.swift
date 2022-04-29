
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
            self.healthDataManager.expirationReached(expirationCode: -2)
            task.setTaskCompleted(success: false)
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
                print("Tasks", tasks.count, tasks);
            })
        }
        scheduleBackgroundDataSend()
        if (healthDataManager.connectionStatus != "Connected") {
            healthDataManager.mqttClient.connectToAWSIoT()
        }
        let connectionTimeoutLimit = Date().timeIntervalSince1970 + 10 //hard limit is a 30s
        var connectionTimeoutLimitReached = false
        while (healthDataManager.connectionStatus != "Connected") {
            if (Date().timeIntervalSince1970 >= connectionTimeoutLimit) {
                self.healthDataManager.expirationReached(expirationCode: -1)
                connectionTimeoutLimitReached = true
                task.setTaskCompleted(success: false)
                break
            }
        }
        if (connectionTimeoutLimitReached == false) {
            self.healthDataManager.queryHeartRateData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.healthDataManager.queryHRVData()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                task.setTaskCompleted(success: true)
            }
        }
        BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
            print("Tasks", tasks.count, tasks);
        })
    }
    
    //Schedules the background app refresh
    func scheduleBackgroundDataSend() {
        let queryTask = BGAppRefreshTaskRequest(identifier: "com.UBCCIC.queryData")
        //Set the minimum background refresh interval in seconds. This interval is not an exact time interval of when each background refresh will be run. Setting the interval states that a background fetch will happen AT MOST once per X seconds, Apple has its own algorithm for scheduling the actual runtimes.
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
}
