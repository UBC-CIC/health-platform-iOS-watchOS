/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the workout view.
*/

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var workoutSession: WorkoutManager
    
    var body: some View {
        VStack(alignment: .leading) {
            // The workout elapsed time.
            Text("\(elapsedTimeString(elapsed: secondsToHoursMinutesSeconds(seconds: workoutSession.elapsedSeconds)))").frame(alignment: .leading)
                .font(Font.system(size: 20, weight: .semibold, design: .default).monospacedDigit())
            Spacer().frame(width: 1, height: 4, alignment: .leading)
            
             //The device id
            Text("ID: \(workoutSession.deviceIDFirst)")
            .font(Font.system(size: 10, weight: .regular, design: .default).monospacedDigit())
            
            Text("\(workoutSession.deviceIDSecond)")
            .font(Font.system(size: 10, weight: .regular, design: .default).monospacedDigit())
            Spacer().frame(width: 1, height: 4, alignment: .leading)
                
            // The heart rate
            Text("HR: \(workoutSession.heartrate, specifier: "%.0f") bpm")
            .font(Font.system(size: 20, weight: .regular, design: .default).monospacedDigit())
            Spacer().frame(width: 1, height: 4, alignment: .leading)
            
            // The heart rate variability
            Text("HRV: \(workoutSession.heartRateVariability, specifier: "%.0f") ms")
            .font(Font.system(size: 20, weight: .regular, design: .default).monospacedDigit())
             
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
    }
    
    // Convert the seconds into seconds, minutes, hours.
    func secondsToHoursMinutesSeconds (seconds: Int) -> (Int, Int, Int) {
      return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    // Convert the seconds, minutes, hours into a string.
    func elapsedTimeString(elapsed: (h: Int, m: Int, s: Int)) -> String {
        return String(format: "%d:%02d:%02d", elapsed.h, elapsed.m, elapsed.s)
    }
    
    
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutView().environmentObject(WorkoutManager())
    }
}
