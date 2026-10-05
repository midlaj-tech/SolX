import SwiftUI

/// SunAngleCompassCard: Floating frosted glass card with glowing solar dial and astronomical telemetry.
/// Matches the exact visual hierarchy in the SolX interface preview.
public struct SunAngleCompassCard: View {
    @ObservedObject var engine = SolarEphemerisEngine.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    public init() {}
    
    public var body: some View {
        let snapshot = engine.snapshot
        
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Text("SUN ANGLE\nCOMPASS")
                .font(.system(size: 11, weight: .bold, design: .default))
                .tracking(1.2)
                .foregroundColor(theme.primaryText.opacity(0.85))
                .lineSpacing(2)
            
            // Circular Compass Dial
            ZStack {
                // Outer subtle ring
                Circle()
                    .stroke(theme.compassDialTrack, lineWidth: 1)
                    .frame(width: 100, height: 100)
                
                // Frosted dial fill
                Circle()
                    .fill(theme.compassDialBackground)
                    .frame(width: 98, height: 98)
                
                // Cardinal markers: N, E, S, W
                VStack {
                    Text("N")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(theme.primaryText.opacity(0.8))
                    Spacer()
                    Text("S")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(theme.primaryText.opacity(0.6))
                }
                .frame(height: 88)
                
                HStack {
                    Text("W")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(theme.primaryText.opacity(0.7))
                    Spacer()
                    Text("E")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(theme.primaryText.opacity(0.7))
                }
                .frame(width: 88)
                
                // Golden sun path arc (approx sunrise to sunset azimuth arc)
                Circle()
                    .trim(from: 0.15, to: 0.65)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.98, green: 0.72, blue: 0.15).opacity(0.2),
                                Color(red: 0.98, green: 0.72, blue: 0.15),
                                Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.8),
                                Color(red: 0.98, green: 0.72, blue: 0.15).opacity(0.3)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: 86, height: 86)
                    .shadow(color: Color(red: 0.98, green: 0.72, blue: 0.15).opacity(0.7), radius: 6, x: 0, y: 0)
                
                // Current Sun Azimuth Indicator
                let angle = Angle.degrees(snapshot.azimuth - 90) // 0° is North (top)
                let radius: CGFloat = 43.0
                let sunX = radius * CGFloat(cos(angle.radians))
                let sunY = radius * CGFloat(sin(angle.radians))
                
                // Sun Dot & Glowing Core
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.35))
                        .frame(width: 18, height: 18)
                        .blur(radius: 2)
                    
                    Circle()
                        .stroke(Color(red: 1.0, green: 0.85, blue: 0.3), lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                }
                .offset(x: sunX, y: sunY)
                
                // Azimuth readout label in center
                HStack(spacing: 3) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 7))
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                    Text(snapshot.azimuthCompassString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(theme.cardBackground.opacity(0.8))
                .clipShape(Capsule())
            }
            .frame(width: 110, height: 110)
            .padding(.vertical, 4)
            
            // Astronomical Telemetry Values
            VStack(alignment: .leading, spacing: 3) {
                Text("Sun: \(snapshot.azimuthCompassString), Alt: \(snapshot.altitudeString)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.primaryText.opacity(0.95))
                
                Text("Sunset: \(formatTime(snapshot.sunset))")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(theme.secondaryText)
                
                Text("Sunrise: \(formatTime(snapshot.sunrise))")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(theme.secondaryText)
                
                HStack(spacing: 4) {
                    Text("Next:")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(theme.secondaryText)
                    
                    Text("Golden Hour (\(snapshot.countdownFormatted))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.goldenAccent)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(theme.cardBorderColor, lineWidth: 1)
                )
                .overlay(
                    // Specular Rim Light
                    theme.specularHighlight
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
        )
        .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.45 : 0.12), radius: 16, x: 0, y: 8)
        .frame(width: 148)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
