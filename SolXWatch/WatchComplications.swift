import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Watch Complication Entry
public struct WatchComplicationEntry: TimelineEntry {
    public let date: Date
    public let snapshot: SolarSnapshot
    
    public init(date: Date, snapshot: SolarSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

// MARK: - Watch Complication Provider
public struct WatchComplicationProvider: TimelineProvider {
    public typealias Entry = WatchComplicationEntry
    
    public func placeholder(in context: Context) -> WatchComplicationEntry {
        let coord = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
        let snapshot = SolarMath.shared.createSnapshot(coordinate: coord, date: Date())
        return WatchComplicationEntry(date: Date(), snapshot: snapshot)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        let coord = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
        let snapshot = SolarMath.shared.createSnapshot(coordinate: coord, date: Date())
        completion(WatchComplicationEntry(date: Date(), snapshot: snapshot))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let now = Date()
        let coord = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
        var entries: [WatchComplicationEntry] = []
        
        for offset in stride(from: 0, to: 360, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: offset, to: now)!
            let snapshot = SolarMath.shared.createSnapshot(coordinate: coord, date: entryDate)
            entries.append(WatchComplicationEntry(date: entryDate, snapshot: snapshot))
        }
        
        let reloadDate = Calendar.current.date(byAdding: .minute, value: 30, to: now)!
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }
}

public struct SolXWatchComplication: Widget {
    public let kind: String = "SolXWatchComplication"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
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
    public let entry: WatchComplicationEntry
    
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
