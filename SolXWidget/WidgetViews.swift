import WidgetKit
import SwiftUI

// MARK: - Root Entry View Router
public struct SolXWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public let entry: SolXWidgetEntry
    
    public init(entry: SolXWidgetEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .systemSmall:
            SmallCountdownWidgetView(entry: entry)
        case .systemMedium:
            MediumCountdownWidgetView(entry: entry)
        case .systemLarge:
            LargeCountdownWidgetView(entry: entry)
        case .accessoryCircular:
            CircularAccessoryWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularAccessoryWidgetView(entry: entry)
        case .accessoryInline:
            InlineAccessoryWidgetView(entry: entry)
        @unknown default:
            SmallCountdownWidgetView(entry: entry)
        }
    }
}

// MARK: - Small System Widget
public struct SmallCountdownWidgetView: View {
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        let snapshot = entry.snapshot
        
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                    Text("SOLX")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.0)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text(snapshot.altitudeString)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
            }
            
            Spacer()
            
            // Countdown Label
            Text("NEXT GOLDEN HOUR")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundColor(.white.opacity(0.65))
            
            // Live Second-by-Second Countdown
            Text(snapshot.nextGoldenHourStart, style: .relative)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Bottom Info: Window and Location
            HStack {
                Text("\(formatTime(snapshot.eveningGoldenHourStart))–\(formatTime(snapshot.eveningGoldenHourEnd))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                Spacer()
                Text(entry.locationName)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(4)
    }
}

// MARK: - Medium System Widget
public struct MediumCountdownWidgetView: View {
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        let snapshot = entry.snapshot
        
        HStack(spacing: 14) {
            // Left Column: Prominent Countdown & Sun Dial
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                    Text("SOLX GOLDEN HOUR")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                Text("STARTS IN")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(snapshot.nextGoldenHourStart, style: .relative)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("Window: \(formatTime(snapshot.eveningGoldenHourStart)) – \(formatTime(snapshot.eveningGoldenHourEnd))")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Right Column: Telemetry & Ephemeris Strip
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(entry.locationName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("GPS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.18))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                TelemetryLine(label: "Sun Bearing:", value: snapshot.azimuthCompassString)
                TelemetryLine(label: "Elevation:", value: snapshot.altitudeString)
                TelemetryLine(label: "Sunset:", value: formatTime(snapshot.sunset))
                TelemetryLine(label: "Sunrise:", value: formatTime(snapshot.sunrise))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
    }
}

// MARK: - Large System Widget
public struct LargeCountdownWidgetView: View {
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        let snapshot = entry.snapshot
        
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                    Text("SOLX EPHEMERIS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.2)
                        .foregroundColor(.white)
                }
                Spacer()
                Text(entry.locationName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Central Countdown Banner
            VStack(spacing: 4) {
                Text("NEXT GOLDEN HOUR COUNTDOWN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(Color(red: 0.98, green: 0.72, blue: 0.15))
                
                Text(snapshot.nextGoldenHourStart, style: .relative)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Evening Window: \(formatTime(snapshot.eveningGoldenHourStart)) – \(formatTime(snapshot.eveningGoldenHourEnd))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
            
            // 4 Phase Schedule Cards
            HStack(spacing: 8) {
                PhaseCardMini(title: "Afternoon", time: formatTime(snapshot.sunset.addingTimeInterval(-79 * 60)), color: .white.opacity(0.6))
                PhaseCardMini(title: "Golden", time: "\(formatTime(snapshot.eveningGoldenHourStart))", color: Color(red: 0.98, green: 0.72, blue: 0.15))
                PhaseCardMini(title: "Blue Hour", time: "\(formatTime(snapshot.eveningBlueHourStart))", color: Color(red: 0.22, green: 0.47, blue: 0.88))
                PhaseCardMini(title: "Night", time: formatTime(snapshot.sunset.addingTimeInterval(71 * 60)), color: .white.opacity(0.5))
            }
            
            // Telemetry Grid
            HStack {
                TelemetryLine(label: "Azimuth:", value: snapshot.azimuthCompassString)
                Spacer()
                TelemetryLine(label: "Altitude:", value: snapshot.altitudeString)
                Spacer()
                TelemetryLine(label: "Sunset:", value: formatTime(snapshot.sunset))
            }
            .padding(.top, 4)
        }
        .padding(4)
    }
}

// MARK: - Lock Screen Accessories
public struct CircularAccessoryWidgetView: View {
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 11))
                Text(entry.snapshot.nextGoldenHourStart, style: .relative)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

public struct RectangularAccessoryWidgetView: View {
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: "sun.horizon.fill")
                Text("SolX Golden Hour")
                    .font(.system(size: 10, weight: .bold))
            }
            Text(entry.snapshot.nextGoldenHourStart, style: .relative)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text("\(formatTime(entry.snapshot.eveningGoldenHourStart))–\(formatTime(entry.snapshot.eveningGoldenHourEnd)) • Alt \(entry.snapshot.altitudeString)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

public struct InlineAccessoryWidgetView: View {
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sun.horizon.fill")
            Text("Golden Hour in ")
            Text(entry.snapshot.nextGoldenHourStart, style: .relative)
        }
    }
}

// MARK: - Background & Helpers
public struct WidgetBackgroundView: View {
    let phase: SolarPhase
    
    public var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.09, blue: 0.14)
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.72, blue: 0.15).opacity(0.16),
                    Color(red: 0.12, green: 0.22, blue: 0.45).opacity(0.20),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct TelemetryLine: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
        }
    }
}

private struct PhaseCardMini: View {
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
            Text(time)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}
