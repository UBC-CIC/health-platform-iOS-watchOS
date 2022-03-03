
import SwiftUI

@main
struct HealthPlatformWatchOSApp: App {
    var healthDataManager = HealthDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(healthDataManager)
        }
    }
}
