
import Foundation
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    var healthDataManager = HealthDataManager()
    
    //Lock application orientation in portrait mode
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
    //Set the minimum background fetch interval in seconds. This interval is not an exact time interval of when each background fetch will be run. Setting the interval states that a background fetch will happen AT MOST once per X seconds, Apple determines the actual runtimes.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        return true
    }

    //Execute HealthKit Query and send to IoT synchonously on the background thread after verifying there is a connection to IoT. If this cannot be completed within the seconds specified by connectionTimeoutLimit, the background fetch will fail.
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DispatchQueue.global(qos: .background).sync {
            var connectionTimeoutCount = 0
            let connectionTimeoutLimit = 25 //Hard limit for a background fetch is 30s
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                connectionTimeoutCount += 1
                if self.healthDataManager.connectionStatus == "Connected" {
                    self.healthDataManager.queryHeartRateData()
                    self.healthDataManager.queryHRVData()
                    completionHandler(.newData)
                    timer.invalidate()
                } else if connectionTimeoutCount == connectionTimeoutLimit {
                    completionHandler(.failed)
                    timer.invalidate()
                }
            }
        }
    }
}
