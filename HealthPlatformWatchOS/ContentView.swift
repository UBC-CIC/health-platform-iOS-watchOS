
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        
        Text("IoT Status: \(healthDataManager.connectionStatus)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .onAppear() {
                healthDataManager.setupSession()
            }
            .padding()
        
        Text("Device ID: \(healthDataManager.deviceID)")
            .padding()
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("Last Query Time: \(healthDataManager.lastQueryTime)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Text("HR Sent: \(healthDataManager.HRDataPointsSent) datapoints")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Text("HRV Sent: \(healthDataManager.HRVDataPointsSent) datapoints")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Button("Query Data") {
            healthDataManager.queryHeartRateData()
            healthDataManager.queryHRVData()
        }.font(Font.system(size: 40, weight: .regular, design: .default).monospacedDigit())

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
