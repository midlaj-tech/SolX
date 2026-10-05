import SwiftUI
import CoreLocation

/// SolarTrajectoryMapView: 2D & Horizon solar trajectory visualizer showing sun elevation arc through the sky.
public struct SolarTrajectoryMapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var engine = SolarEphemerisEngine.shared
    @ObservedObject var theme = ThemeManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Solar Sky Dome Arc
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SOLAR TRAJECTORY ARC")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(theme.primaryText.opacity(0.85))
                        
                        GeometryReader { geo in
                            let w = geo.size.width
                            let h = geo.size.height
                            let groundY = h * 0.75
                            
                            ZStack {
                                // Sky background gradient
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.08, green: 0.15, blue: 0.32),
                                                Color(red: 0.18, green: 0.35, blue: 0.65),
                                                Color(red: 0.95, green: 0.65, blue: 0.35).opacity(0.6)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                
                                // Ground / Horizon line
                                Path { p in
                                    p.move(to: CGPoint(x: 0, y: groundY))
                                    p.addLine(to: CGPoint(x: w, y: groundY))
                                }
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                
                                // Horizon label
                                Text("HORIZON (0°)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .position(x: 45, y: groundY - 10)
                                
                                // Golden Hour band (-4° to +6°)
                                let goldenBandTop = groundY - (h * 0.12)
                                let goldenBandBottom = groundY + (h * 0.08)
                                Rectangle()
                                    .fill(Color(red: 0.98, green: 0.72, blue: 0.15).opacity(0.18))
                                    .frame(width: w, height: goldenBandBottom - goldenBandTop)
                                    .position(x: w / 2, y: (goldenBandTop + goldenBandBottom) / 2)
                                
                                Text("GOLDEN HOUR BAND (-4° to +6°)")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.8))
                                    .position(x: w / 2, y: goldenBandTop + 10)
                                
                                // Parabolic sun arc path through sky
                                Path { p in
                                    p.move(to: CGPoint(x: w * 0.1, y: groundY + 15))
                                    p.addQuadCurve(
                                        to: CGPoint(x: w * 0.9, y: groundY + 15),
                                        control: CGPoint(x: w * 0.5, y: h * 0.1)
                                    )
                                }
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.98, green: 0.72, blue: 0.15),
                                            Color(red: 1.0, green: 0.9, blue: 0.5),
                                            Color(red: 0.98, green: 0.72, blue: 0.15)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                
                                // Current Sun Position on Arc
                                let currentAlt = engine.snapshot.altitude
                                let normAlt = max(-15.0, min(75.0, currentAlt)) / 75.0
                                let sunY = groundY - (normAlt * (groundY - (h * 0.1)))
                                
                                // Map azimuth roughly along x (sunrise E=90° ~ left, noon S=180° ~ center, sunset W=270° ~ right)
                                let az = engine.snapshot.azimuth
                                let normAz = max(0.1, min(0.9, (az - 60.0) / 240.0))
                                let sunX = w * CGFloat(normAz)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4))
                                        .frame(width: 32, height: 32)
                                        .blur(radius: 6)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 14, height: 14)
                                    Circle()
                                        .stroke(Color(red: 0.98, green: 0.72, blue: 0.15), lineWidth: 2)
                                        .frame(width: 14, height: 14)
                                }
                                .position(x: sunX, y: sunY)
                            }
                        }
                        .frame(height: 220)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(theme.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.cardBorderColor, lineWidth: 1))
                    )
                    
                    // Astronomical Transit Details
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ASTRONOMICAL PHASES TODAY")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(theme.primaryText.opacity(0.85))
                        
                        PhaseRow(name: "Morning Blue Hour", time: "\(fmt(engine.snapshot.morningBlueHourStart)) – \(fmt(engine.snapshot.morningBlueHourEnd))", tag: "Dawn", color: theme.blueHourAccent)
                        Divider()
                        PhaseRow(name: "Morning Golden Hour", time: "\(fmt(engine.snapshot.morningGoldenHourStart)) – \(fmt(engine.snapshot.morningGoldenHourEnd))", tag: "Sunrise", color: theme.goldenAccent)
                        Divider()
                        PhaseRow(name: "Solar Noon", time: fmt(engine.snapshot.solarNoon), tag: "Peak", color: .yellow)
                        Divider()
                        PhaseRow(name: "Evening Golden Hour", time: "\(fmt(engine.snapshot.eveningGoldenHourStart)) – \(fmt(engine.snapshot.eveningGoldenHourEnd))", tag: "Sunset", color: theme.goldenAccent)
                        Divider()
                        PhaseRow(name: "Evening Blue Hour", time: "\(fmt(engine.snapshot.eveningBlueHourStart)) – \(fmt(engine.snapshot.eveningBlueHourEnd))", tag: "Dusk", color: theme.blueHourAccent)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(theme.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.cardBorderColor, lineWidth: 1))
                    )
                }
                .padding(16)
            }
            .navigationTitle("Solar Ephemeris Trajectory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.goldenAccent)
                }
            }
        }
        .preferredColorScheme(theme.preferredColorScheme)
    }
    
    private func fmt(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

private struct PhaseRow: View {
    let name: String
    let time: String
    let tag: String
    let color: Color
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(theme.primaryText.opacity(0.9))
            
            Text(tag)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
        }
    }
}
