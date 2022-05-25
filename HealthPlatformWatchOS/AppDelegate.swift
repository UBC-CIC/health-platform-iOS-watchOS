
import UIKit
import BackgroundTasks
    
class AppDelegate: NSObject, UIApplicationDelegate {
    var healthDataManager = HealthDataManager()
    var bgTaskError = false
        
    //Lock application orientation in portrait mode
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
    //Register the background refresh task and schedule task
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.HealthPlatform.queryData",
          using: nil) { (task) in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        var scheduledTasks = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { tasks in
                scheduledTasks = tasks.count
            })
            if (self.bgTaskError == true) {
                self.healthDataManager.expirationReached(expirationCode: "Unable to register a BGTask")
                timer.invalidate()
            } else if (scheduledTasks == 0) {
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
            self.healthDataManager.expirationReached(expirationCode: "Last BGTask Expiration Handler Reached")
            self.healthDataManager.updateUIValues()
            task.setTaskCompleted(success: false)
        }
        scheduleBackgroundDataSend()
        if (healthDataManager.connectionStatus != "Connected") {
            healthDataManager.mqttClient.connectToAWSIoT()
        }
        let connectionTimeoutLimit = Date().timeIntervalSince1970 + 15 //hard limit for total runtime is 30s
        var connectionTimeoutLimitReached = false
        while (healthDataManager.connectionStatus != "Connected") {
            if (Date().timeIntervalSince1970 >= connectionTimeoutLimit) {
                self.healthDataManager.expirationReached(expirationCode: "Last BGTask Was Unable to Connect")
                connectionTimeoutLimitReached = true
                task.setTaskCompleted(success: false)
                break
            }
        }
        if (connectionTimeoutLimitReached == false) {
            self.healthDataManager.sendDataToAWSBGTask()
            DispatchQueue.main.asyncAfter(deadline: .now() + 13.0) {
                self.healthDataManager.expirationReached(expirationCode: "")
                self.healthDataManager.updateUIValues()
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    //Schedules the background app refresh
    func scheduleBackgroundDataSend() {
        let queryTask = BGAppRefreshTaskRequest(identifier: "com.HealthPlatform.queryData")
        //Set the minimum background refresh interval in seconds. This interval is not an exact time interval of when each background refresh will be run. Setting the interval states that a background fetch will happen AT MOST once per X seconds, Apple has its own algorithm for scheduling the actual runtimes.
        queryTask.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 6)
        do {
            try BGTaskScheduler.shared.submit(queryTask)
        } catch {
            bgTaskError = true
            print("Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    //Cancel all task requests when the app is force quit
    func applicationWillTerminate(_ application: UIApplication) {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}
