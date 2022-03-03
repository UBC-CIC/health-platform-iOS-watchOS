
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    
    var body: some View {
        Text("Health Platform iOS")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
            .onAppear() {
                healthDataManager.setupSession()
            }
        Text("Watch ID: \(healthDataManager.deviceID)")
            .padding()
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("Heart Rate: \(healthDataManager.heartRate, specifier: "%.0f") bpm")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Text("Heart Rate Variability:\(healthDataManager.heartRateVariability, specifier: "%.0f") ms")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
