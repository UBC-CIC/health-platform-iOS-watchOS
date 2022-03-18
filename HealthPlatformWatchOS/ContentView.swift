
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
        
        Text("Last Send Time: \(healthDataManager.lastQueryTime)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Text("HR Sent: \(healthDataManager.HRDataPointsSent) datapoints")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Text("HRV Sent: \(healthDataManager.HRVDataPointsSent) datapoints")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Button("Send Data") {
            healthDataManager.queryHeartRateData()
            healthDataManager.queryHRVData()
        }.buttonStyle(GrowingButton())
            .font(Font.system(size: 40, weight: .regular, design: .default).monospacedDigit())
    }
}

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
