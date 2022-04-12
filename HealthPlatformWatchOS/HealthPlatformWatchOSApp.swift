
import SwiftUI

@main
struct HealthPlatformWatchOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appDelegate.healthDataManager)
        }
    }
}
