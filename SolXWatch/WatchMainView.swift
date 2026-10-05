import SwiftUI
import CoreLocation
import Combine
#if canImport(WatchKit)
import WatchKit
#endif

/// WatchMainView: Lightweight, glanceable wrist companion for photographers.
/// Displays next golden hour countdown, solar elevation gauge, and azimuth bearing.
public struct WatchMainView: View {
    @State private var currentDate = Date()
    @State private var crownOffsetMinutes: Double = 0.0
    
    // Default coordinate (Kannur or device GPS)
    private let coordinate = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        let simulatedDate = currentDate.addingTimeInterval(crownOffsetMinutes * 60)
        let snapshot = SolarMath.shared.createSnapshot(coordinate: coordinate, date: simulatedDate)
        
        ScrollView {
            VStack(spacing: 8) {
                // Top Header Pill: Location & Phase
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(snapshot.currentPhase.color)
                            .frame(width: 6, height: 6)
                        Text(snapshot.currentPhase.displayName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(snapshot.currentPhase.color)
                            .lineLimit(1)
                    }
                    Spacer()
                    if crownOffsetMinutes != 0 {
                        Button(action: {
                            crownOffsetMinutes = 0
                            #if canImport(WatchKit)
                            WKInterfaceDevice.current().play(.click)
                            #endif
                        }) {
                            Text("NOW")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                // Central Solar Elevation Gauge & Countdown
                ZStack {
                    // Circular Gauge Track
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 5)
                        .frame(width: 104, height: 104)
                    
                    // Golden Progress Arc
                    let progress = max(0.05, min(0.95, (snapshot.altitude + 15.0) / 90.0))
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            AngularGradient(
                                colors: [Color(red: 0.98, green: 0.72, blue: 0.15), Color(red: 1.0, green: 0.88, blue: 0.45)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 104, height: 104)
                    
                    // Inside Circle: Live Countdown
                    VStack(spacing: 1) {
                        Text("GOLDEN IN")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.6)
                            .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                        
                        Text(snapshot.countdownFormatted)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(snapshot.altitudeString)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 2)
                
                // Telemetry Strip: Azimuth & Sunset
                HStack(spacing: 8) {
                    WatchMetricCell(
                        icon: "safari.fill",
                        label: "Bearing",
                        value: snapshot.azimuthCompassString,
                        accent: .white
                    )
                    
                    WatchMetricCell(
                        icon: "sunset.fill",
                        label: "Sunset",
                        value: formatTime(snapshot.sunset),
                        accent: Color(red: 0.98, green: 0.72, blue: 0.15)
                    )
                }
                
                // Digital Crown Hint
                if crownOffsetMinutes == 0 {
                    Text("Rotate Crown to preview daylight")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 2)
                } else {
                    let offsetInt = Int(crownOffsetMinutes)
                    Text("Preview: \(offsetInt > 0 ? "+\(offsetInt)" : "\(offsetInt)") min (\(formatTime(simulatedDate)))")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 6)
        }
        .focusable()
        .digitalCrownRotation(
            $crownOffsetMinutes,
            from: -180,
            through: 360,
            by: 5,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onReceive(timer) { now in
            currentDate = now
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct WatchMetricCell: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(accent)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
    }
}
