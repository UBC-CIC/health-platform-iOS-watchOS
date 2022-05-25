
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        (Text("IoT Status: \(healthDataManager.connectionStatus)") + Text(Image(systemName: healthDataManager.connectionStatusIcon))
            .foregroundColor(healthDataManager.connectionStatusIconColour))
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .onAppear() {
                healthDataManager.setupSession()
            }
        
        Text("Device ID: \(healthDataManager.deviceID)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
            .padding()
        
        Text("Last Send Time: \(healthDataManager.lastQueryTime)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("HR Sent: \(healthDataManager.HRDataPointsSent) datapoints")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("HRV Sent: \(healthDataManager.HRVDataPointsSent) datapoints")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("BGTasks: \(healthDataManager.remainingBGTasks) remaining")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("Earliest BGTask Time: \(healthDataManager.earliestBGTaskExecutionDate)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Text("\(healthDataManager.error)")
            .font(Font.system(size: 25, weight: .regular, design: .default).monospacedDigit())
        
        Button("Send Data") {
            healthDataManager.sendDataToAWSButton()
        }.buttonStyle(GrowingButton())
            .font(Font.system(size: 30, weight: .regular, design: .default).monospacedDigit())
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
