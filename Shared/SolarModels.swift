import Foundation
import CoreLocation
import SwiftUI

// MARK: - Solar Lighting Phase
public enum SolarPhase: String, CaseIterable, Identifiable, Sendable {
    case night = "Night"
    case morningAstronomicalTwilight = "Astronomical Twilight (Dawn)"
    case morningNauticalTwilight = "Nautical Twilight (Dawn)"
    case morningBlueHour = "Blue Hour (Morning)"
    case morningGoldenHour = "Golden Hour (Morning)"
    case daylight = "Daylight"
    case afternoon = "Afternoon"
    case eveningGoldenHour = "Golden Hour (Evening)"
    case eveningBlueHour = "Blue Hour (Evening)"
    case eveningNauticalTwilight = "Nautical Twilight (Dusk)"
    case eveningAstronomicalTwilight = "Astronomical Twilight (Dusk)"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .morningGoldenHour: return "Golden Hour (Dawn)"
        case .eveningGoldenHour: return "Golden Hour"
        case .morningBlueHour: return "Blue Hour (Dawn)"
        case .eveningBlueHour: return "Blue Hour"
        case .afternoon: return "Afternoon"
        case .daylight: return "Daylight"
        case .night: return "Night"
        case .morningAstronomicalTwilight, .eveningAstronomicalTwilight: return "Astro Twilight"
        case .morningNauticalTwilight, .eveningNauticalTwilight: return "Nautical Twilight"
        }
    }

    public var isGolden: Bool {
        self == .morningGoldenHour || self == .eveningGoldenHour
    }

    public var isBlue: Bool {
        self == .morningBlueHour || self == .eveningBlueHour
    }

    public var color: Color {
        switch self {
        case .morningGoldenHour, .eveningGoldenHour:
            return Color(red: 0.98, green: 0.72, blue: 0.15) // Solar Gold
        case .morningBlueHour, .eveningBlueHour:
            return Color(red: 0.22, green: 0.47, blue: 0.88) // Deep Twilight Blue
        case .afternoon, .daylight:
            return Color(red: 0.95, green: 0.82, blue: 0.45) // Warm Sunlight
        case .morningNauticalTwilight, .eveningNauticalTwilight:
            return Color(red: 0.16, green: 0.28, blue: 0.52)
        case .morningAstronomicalTwilight, .eveningAstronomicalTwilight:
            return Color(red: 0.08, green: 0.14, blue: 0.32)
        case .night:
            return Color(red: 0.05, green: 0.07, blue: 0.15)
        }
    }

    public var iconName: String {
        switch self {
        case .morningGoldenHour, .eveningGoldenHour: return "sun.horizon.fill"
        case .morningBlueHour, .eveningBlueHour: return "moon.stars.fill"
        case .daylight, .afternoon: return "sun.max.fill"
        case .night: return "moon.fill"
        default: return "sparkles"
        }
    }
}

// MARK: - Solar Snapshot
public struct SolarSnapshot: Identifiable, Sendable {
    public var id: String { "\(date.timeIntervalSince1970)-\(coordinate.latitude)-\(coordinate.longitude)" }

    public let date: Date
    public let coordinate: CLLocationCoordinate2D
    public let altitude: Double            // in degrees (-90° to +90°)
    public let azimuth: Double             // in degrees (0° to 360°, North = 0°)
    public let currentPhase: SolarPhase
    
    // Core Astronomical Milestones
    public let sunrise: Date
    public let sunset: Date
    public let solarNoon: Date
    
    // Golden Hour Windows
    public let morningGoldenHourStart: Date
    public let morningGoldenHourEnd: Date
    public let eveningGoldenHourStart: Date
    public let eveningGoldenHourEnd: Date
    
    // Blue Hour Windows
    public let morningBlueHourStart: Date
    public let morningBlueHourEnd: Date
    public let eveningBlueHourStart: Date
    public let eveningBlueHourEnd: Date
    
    // Countdown to Next Golden Hour
    public let nextGoldenHourStart: Date
    public let nextGoldenHourEnd: Date
    public let isNextGoldenMorning: Bool
    public let timeToNextGoldenHour: TimeInterval
    
    // Compass cardinal direction
    public var azimuthCompassString: String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(round(azimuth / 22.5)) % 16
        let cardinal = directions[max(0, min(15, index))]
        return "\(Int(round(azimuth)))° \(cardinal)"
    }
    
    public var altitudeString: String {
        let sign = altitude >= 0 ? "+" : ""
        return "\(sign)\(Int(round(altitude)))°"
    }

    public var countdownFormatted: String {
        if timeToNextGoldenHour <= 0 {
            return "Active Now"
        }
        let totalSeconds = Int(timeToNextGoldenHour)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Timeline Item
public struct EphemerisTimelineItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let timeString: String
    public let phase: SolarPhase
    public let isHighlighted: Bool
}
