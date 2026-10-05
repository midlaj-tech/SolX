import WidgetKit
import SwiftUI
import CoreLocation

public struct SolXWatchComplication: Widget {
    public let kind: String = "SolXWatchComplication"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SolXTimelineProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("SolX Golden Hour")
        .description("Glanceable golden hour countdown for your Apple Watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

public struct WatchComplicationView: View {
    @Environment(\.widgetFamily) var family
    public let entry: SolXWidgetEntry
    
    public var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 11))
                    Text(entry.snapshot.countdownFormatted)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                }
            }
        case .accessoryCorner:
            ZStack {
                Text(entry.snapshot.countdownFormatted)
                    .font(.system(size: 10, weight: .bold))
                    .widgetCurvesContent()
                    .widgetLabel {
                        Text("GOLDEN")
                    }
            }
        case .accessoryInline:
            HStack(spacing: 3) {
                Image(systemName: "sun.horizon.fill")
                Text("Golden in \(entry.snapshot.countdownFormatted)")
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "sun.horizon.fill")
                    Text("SolX Golden Hour")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(entry.snapshot.countdownFormatted)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text("Alt \(entry.snapshot.altitudeString) • \(entry.snapshot.azimuthCompassString)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        @unknown default:
            Text(entry.snapshot.countdownFormatted)
        }
    }
}
