import SwiftUI

/// EphemerisTimelineCard: Interactive bottom timeline scrubber with solar lighting spectrum bar and phase columns.
/// Faithfully reproduces the Ephemeris Timeline from the SolX design specification.
public struct EphemerisTimelineCard: View {
    @ObservedObject var engine = SolarEphemerisEngine.shared
    @ObservedObject var theme = ThemeManager.shared
    
    @State private var scrubFraction: Double = 0.77 // default near evening golden hour
    @State private var isDragging: Bool = false
    
    public init() {}
    
    public var body: some View {
        let snapshot = engine.snapshot
        
        VStack(alignment: .leading, spacing: 10) {
            // Header with reset button if scrubbing
            HStack {
                Text("EPHEMERIS TIMELINE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(theme.primaryText.opacity(0.85))
                
                Spacer()
                
                if engine.isScrubbing {
                    Button(action: {
                        engine.resetToLiveTime()
                        HapticService.trigger(.medium)
                    }) {
                        Text("RESET LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.goldenAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.goldenAccent.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Interactive Slider & Thumb
            GeometryReader { geo in
                let width = geo.size.width
                
                ZStack(alignment: .leading) {
                    // Thin track line
                    Rectangle()
                        .fill(theme.compassDialTrack)
                        .frame(height: 2)
                        .cornerRadius(1)
                    
                    // Left and right endpoint icons
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 9))
                            .foregroundColor(theme.secondaryText)
                        Spacer()
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 10))
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    // Golden Sun Thumb Indicator with Glow
                    let thumbX = max(0, min(width, width * currentFraction(snapshot: snapshot)))
                    
                    ZStack {
                        // Ambient solar flare glow
                        Circle()
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.35).opacity(0.45))
                            .frame(width: 28, height: 28)
                            .blur(radius: 6)
                        
                        // Solid core
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.95, blue: 0.7),
                                        Color(red: 0.98, green: 0.72, blue: 0.15)
                                    ]),
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 9
                                )
                            )
                            .frame(width: 18, height: 18)
                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                    }
                    .position(x: thumbX, y: 10)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = max(0.0, min(1.0, Double(value.location.x / width)))
                            self.scrubFraction = fraction
                            self.isDragging = true
                            engine.beginScrubbing()
                            engine.scrubTo(fractionOfDay: fraction)
                        }
                        .onEnded { _ in
                            self.isDragging = false
                            HapticService.trigger(.light)
                        }
                )
            }
            .frame(height: 20)
            
            // Color Spectrum Gradient Bar
            HStack(spacing: 0) {
                // Afternoon warm amber
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.78, blue: 0.40), Color(red: 0.98, green: 0.68, blue: 0.20)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                
                // Golden Hour brilliant gold
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.68, blue: 0.20), Color(red: 0.98, green: 0.75, blue: 0.15)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                
                // Blue Hour sapphire transition
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.22, green: 0.47, blue: 0.88), Color(red: 0.12, green: 0.25, blue: 0.58)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                
                // Night deep navy
                Rectangle()
                    .fill(Color(red: 0.06, green: 0.09, blue: 0.18))
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 6)
            .cornerRadius(3)
            .padding(.vertical, 2)
            
            // 4-Column Ephemeris Phase Schedule
            HStack(alignment: .top, spacing: 0) {
                // Column 1: Afternoon
                PhaseColumn(
                    title: "Afternoon",
                    time: formatTime(snapshot.sunset.addingTimeInterval(-79 * 60)),
                    color: theme.secondaryText,
                    isActive: snapshot.currentPhase == .afternoon
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Column 2: Golden Hour (Highlighted)
                PhaseColumn(
                    title: "Golden Hour",
                    time: "\(formatTime(snapshot.eveningGoldenHourStart))–\(formatTime(snapshot.eveningGoldenHourEnd))",
                    color: theme.goldenAccent,
                    isActive: snapshot.currentPhase.isGolden
                )
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Column 3: Blue Hour (Highlighted)
                PhaseColumn(
                    title: "Blue Hour",
                    time: "\(formatTime(snapshot.eveningBlueHourStart))–\(formatTime(snapshot.eveningBlueHourEnd))",
                    color: theme.blueHourAccent,
                    isActive: snapshot.currentPhase.isBlue
                )
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Column 4: Night
                PhaseColumn(
                    title: "Night",
                    time: formatTime(snapshot.sunset.addingTimeInterval(71 * 60)),
                    color: theme.secondaryText,
                    isActive: snapshot.currentPhase == .night
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
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
                    theme.specularHighlight
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
        )
        .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.45 : 0.12), radius: 16, x: 0, y: 8)
    }
    
    private func currentFraction(snapshot: SolarSnapshot) -> Double {
        if engine.isScrubbing {
            return scrubFraction
        }
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: snapshot.date)
        let secondsPassed = snapshot.date.timeIntervalSince(startOfDay)
        return max(0.0, min(1.0, secondsPassed / 86400.0))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// Subview for each schedule column
private struct PhaseColumn: View {
    let title: String
    let time: String
    let color: Color
    let isActive: Bool
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: isActive ? .bold : .medium))
                .foregroundColor(color)
            
            Text(time)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(theme.primaryText.opacity(isActive ? 0.95 : 0.65))
        }
    }
}
