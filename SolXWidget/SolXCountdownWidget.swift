import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Timeline Entry
public struct SolXWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: SolarSnapshot
    public let locationName: String
    
    public init(date: Date, snapshot: SolarSnapshot, locationName: String = "Kannur Coast") {
        self.date = date
        self.snapshot = snapshot
        self.locationName = locationName
    }
}

// MARK: - Timeline Provider
public struct SolXTimelineProvider: TimelineProvider {
    public typealias Entry = SolXWidgetEntry
    
    public func placeholder(in context: Context) -> SolXWidgetEntry {
        let coord = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
        let snapshot = SolarMath.shared.createSnapshot(coordinate: coord, date: Date())
        return SolXWidgetEntry(date: Date(), snapshot: snapshot, locationName: "Kannur Coast")
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (SolXWidgetEntry) -> Void) {
        let coord = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
        let snapshot = SolarMath.shared.createSnapshot(coordinate: coord, date: Date())
        let entry = SolXWidgetEntry(date: Date(), snapshot: snapshot, locationName: "Kannur Coast")
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<SolXWidgetEntry>) -> Void) {
        let now = Date()
        let coord = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
        var entries: [SolXWidgetEntry] = []
        
        // Generate entries for every 15 minutes over the next 6 hours
        for minuteOffset in stride(from: 0, to: 360, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now)!
            let snapshot = SolarMath.shared.createSnapshot(coordinate: coord, date: entryDate)
            entries.append(SolXWidgetEntry(date: entryDate, snapshot: snapshot, locationName: "Kannur Coast"))
        }
        
        // Reload after 30 minutes to update with exact GPS and ephemeris
        let reloadDate = Calendar.current.date(byAdding: .minute, value: 30, to: now)!
        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

// MARK: - Widget Definition
public struct SolXCountdownWidget: Widget {
    public let kind: String = "SolXCountdownWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SolXTimelineProvider()) { entry in
            SolXWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView(phase: entry.snapshot.currentPhase)
                }
        }
        .configurationDisplayName("Golden Hour Countdown")
        .description("Track the exact countdown to the next golden hour for photography in your region.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
