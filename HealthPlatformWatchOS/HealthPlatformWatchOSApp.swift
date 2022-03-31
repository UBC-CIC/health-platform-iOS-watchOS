
import SwiftUI

@main
struct HealthPlatformWatchOSApp: App {
//    var healthDataManager = HealthDataManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appDelegate.healthDataManager)
        }
    }
}
