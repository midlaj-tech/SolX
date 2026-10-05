import Foundation
import CoreLocation

/// SolarMath: Rigorous Spherical Trigonometry & NOAA Solar Position Calculations
/// Operates 100% offline on-device with zero network latency.
public final class SolarMath: Sendable {
    
    public static let shared = SolarMath()
    
    private init() {}
    
    // MARK: - Core Position Calculation
    /// Calculates solar altitude and azimuth for a given coordinate and timestamp.
    public func calculatePosition(coordinate: CLLocationCoordinate2D, date: Date = Date(), timeZone: TimeZone = .current) -> (altitude: Double, azimuth: Double) {
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = timeZone
        
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        let components = cal.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        let fractionalHour = hour + (minute / 60.0) + (second / 3600.0)
        
        // Fractional year γ (in radians)
        let gamma = (2.0 * .pi / 365.0) * (dayOfYear - 1.0 + ((fractionalHour - 12.0) / 24.0))
        
        // Equation of Time (minutes)
        let eqtime = 229.18 * (
            0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2.0 * gamma) -
            0.040849 * sin(2.0 * gamma)
        )
        
        // Solar Declination δ (radians)
        let decl = 0.006918 -
            0.399912 * cos(gamma) +
            0.070257 * sin(gamma) -
            0.006758 * cos(2.0 * gamma) +
            0.000907 * sin(2.0 * gamma) -
            0.002697 * cos(3.0 * gamma) +
            0.001480 * sin(3.0 * gamma)
        
        // Timezone offset in hours
        let tzOffsetHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        
        // True Solar Time (TST in minutes)
        let timeOffset = eqtime + (4.0 * coordinate.longitude) - (60.0 * tzOffsetHours)
        let trueSolarTime = (fractionalHour * 60.0) + timeOffset
        
        // Solar Hour Angle ω (radians)
        let hourAngleDeg = (trueSolarTime / 4.0) - 180.0
        let hourAngle = hourAngleDeg * (.pi / 180.0)
        
        // Latitude in radians
        let latRad = coordinate.latitude * (.pi / 180.0)
        
        // Solar Zenith Angle θ
        var cosZenith = (sin(latRad) * sin(decl)) + (cos(latRad) * cos(decl) * cos(hourAngle))
        cosZenith = max(-1.0, min(1.0, cosZenith))
        let zenith = acos(cosZenith)
        
        // Solar Altitude α (degrees)
        let altitude = 90.0 - (zenith * (180.0 / .pi))
        
        // Solar Azimuth Angle A (degrees from North)
        var cosAzimuth = ((sin(latRad) * cos(zenith)) - sin(decl)) / (cos(latRad) * sin(zenith))
        cosAzimuth = max(-1.0, min(1.0, cosAzimuth))
        var azimuth = acos(cosAzimuth) * (180.0 / .pi)
        
        if hourAngleDeg > 0 {
            azimuth = 360.0 - azimuth
        }
        
        return (altitude: altitude, azimuth: azimuth)
    }
    
    // MARK: - Solar Times for Day
    /// Computes full solar milestone snapshot for location and date
    public func createSnapshot(coordinate: CLLocationCoordinate2D, date: Date = Date(), timeZone: TimeZone = .current) -> SolarSnapshot {
        let (altitude, azimuth) = calculatePosition(coordinate: coordinate, date: date, timeZone: timeZone)
        
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = timeZone
        
        let startOfDay = cal.startOfDay(for: date)
        
        // Calculate solar events for today
        let sunrise = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: -0.833, isRising: true, timeZone: timeZone)
        let sunset = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: -0.833, isRising: false, timeZone: timeZone)
        let solarNoon = calculateSolarNoon(coordinate: coordinate, date: startOfDay, timeZone: timeZone)
        
        // Golden Hour: -4° to +6°
        let morningGoldenStart = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: -4.0, isRising: true, timeZone: timeZone)
        let morningGoldenEnd = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: 6.0, isRising: true, timeZone: timeZone)
        
        let eveningGoldenStart = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: 6.0, isRising: false, timeZone: timeZone)
        let eveningGoldenEnd = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: -4.0, isRising: false, timeZone: timeZone)
        
        // Blue Hour: -6° to -4°
        let morningBlueStart = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: -6.0, isRising: true, timeZone: timeZone)
        let morningBlueEnd = morningGoldenStart
        
        let eveningBlueStart = eveningGoldenEnd
        let eveningBlueEnd = calculateAltitudeCrossing(coordinate: coordinate, date: startOfDay, targetAltitude: -6.0, isRising: false, timeZone: timeZone)
        
        // Determine current phase
        let phase = determinePhase(altitude: altitude, date: date, solarNoon: solarNoon)
        
        // Determine next upcoming Golden Hour
        let (nextGHStart, nextGHEnd, isMorning) = findNextGoldenHour(
            now: date,
            coordinate: coordinate,
            timeZone: timeZone,
            morningStart: morningGoldenStart,
            morningEnd: morningGoldenEnd,
            eveningStart: eveningGoldenStart,
            eveningEnd: eveningGoldenEnd
        )
        
        let timeRemaining = max(0, nextGHStart.timeIntervalSince(date))
        
        return SolarSnapshot(
            date: date,
            coordinate: coordinate,
            altitude: altitude,
            azimuth: azimuth,
            currentPhase: phase,
            sunrise: sunrise,
            sunset: sunset,
            solarNoon: solarNoon,
            morningGoldenHourStart: morningGoldenStart,
            morningGoldenHourEnd: morningGoldenEnd,
            eveningGoldenHourStart: eveningGoldenStart,
            eveningGoldenHourEnd: eveningGoldenEnd,
            morningBlueHourStart: morningBlueStart,
            morningBlueHourEnd: morningBlueEnd,
            eveningBlueHourStart: eveningBlueStart,
            eveningBlueHourEnd: eveningBlueEnd,
            nextGoldenHourStart: nextGHStart,
            nextGoldenHourEnd: nextGHEnd,
            isNextGoldenMorning: isMorning,
            timeToNextGoldenHour: timeRemaining
        )
    }
    
    // MARK: - Internal Astronomical Solvers
    private func calculateSolarNoon(coordinate: CLLocationCoordinate2D, date: Date, timeZone: TimeZone) -> Date {
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = timeZone
        
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        let gamma = (2.0 * .pi / 365.0) * (dayOfYear - 1.0)
        let eqtime = 229.18 * (
            0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2.0 * gamma) -
            0.040849 * sin(2.0 * gamma)
        )
        
        let tzOffsetHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        // Solar noon in minutes from midnight UTC
        let solarNoonMinutes = 720.0 - (4.0 * coordinate.longitude) - eqtime + (tzOffsetHours * 60.0)
        
        return cal.startOfDay(for: date).addingTimeInterval(solarNoonMinutes * 60.0)
    }
    
    private func calculateAltitudeCrossing(
        coordinate: CLLocationCoordinate2D,
        date: Date,
        targetAltitude: Double,
        isRising: Bool,
        timeZone: TimeZone
    ) -> Date {
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = timeZone
        
        let startOfDay = cal.startOfDay(for: date)
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        let gamma = (2.0 * .pi / 365.0) * (dayOfYear - 1.0 + (12.0 - 12.0) / 24.0)
        
        let decl = 0.006918 -
            0.399912 * cos(gamma) +
            0.070257 * sin(gamma) -
            0.006758 * cos(2.0 * gamma) +
            0.000907 * sin(2.0 * gamma) -
            0.002697 * cos(3.0 * gamma) +
            0.001480 * sin(3.0 * gamma)
        
        let eqtime = 229.18 * (
            0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2.0 * gamma) -
            0.040849 * sin(2.0 * gamma)
        )
        
        let latRad = coordinate.latitude * (.pi / 180.0)
        let targetZenithRad = (90.0 - targetAltitude) * (.pi / 180.0)
        
        var cosHA = (cos(targetZenithRad) - (sin(latRad) * sin(decl))) / (cos(latRad) * cos(decl))
        
        // Handle midnight sun or polar night
        if cosHA > 1.0 {
            // Sun never reaches target altitude (polar night)
            return isRising ? startOfDay.addingTimeInterval(6 * 3600) : startOfDay.addingTimeInterval(18 * 3600)
        } else if cosHA < -1.0 {
            // Sun never sets below target altitude (midnight sun)
            return isRising ? startOfDay.addingTimeInterval(0) : startOfDay.addingTimeInterval(24 * 3600)
        }
        
        cosHA = max(-1.0, min(1.0, cosHA))
        let haRad = acos(cosHA)
        let haDeg = haRad * (180.0 / .pi)
        
        let tzOffsetHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let timeMinutes: Double
        
        if isRising {
            timeMinutes = 720.0 - (4.0 * coordinate.longitude) - eqtime - (4.0 * haDeg) + (tzOffsetHours * 60.0)
        } else {
            timeMinutes = 720.0 - (4.0 * coordinate.longitude) - eqtime + (4.0 * haDeg) + (tzOffsetHours * 60.0)
        }
        
        return startOfDay.addingTimeInterval(timeMinutes * 60.0)
    }
    
    private func determinePhase(altitude: Double, date: Date, solarNoon: Date) -> SolarPhase {
        let isAfternoon = date >= solarNoon
        
        if altitude > 6.0 {
            return isAfternoon ? .afternoon : .daylight
        } else if altitude >= -4.0 {
            return isAfternoon ? .eveningGoldenHour : .morningGoldenHour
        } else if altitude >= -6.0 {
            return isAfternoon ? .eveningBlueHour : .morningBlueHour
        } else if altitude >= -12.0 {
            return isAfternoon ? .eveningNauticalTwilight : .morningNauticalTwilight
        } else if altitude >= -18.0 {
            return isAfternoon ? .eveningAstronomicalTwilight : .morningAstronomicalTwilight
        } else {
            return .night
        }
    }
    
    private func findNextGoldenHour(
        now: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        morningStart: Date,
        morningEnd: Date,
        eveningStart: Date,
        eveningEnd: Date
    ) -> (start: Date, end: Date, isMorning: Bool) {
        // If right now we're inside morning golden hour
        if now >= morningStart && now <= morningEnd {
            return (morningStart, morningEnd, true)
        }
        // If morning is in the future today
        if now < morningStart {
            return (morningStart, morningEnd, true)
        }
        // If inside evening golden hour
        if now >= eveningStart && now <= eveningEnd {
            return (eveningStart, eveningEnd, false)
        }
        // If evening is in the future today
        if now < eveningStart {
            return (eveningStart, eveningEnd, false)
        }
        // Otherwise next is tomorrow's morning golden hour
        let tomorrow = now.addingTimeInterval(24 * 3600)
        let cal = Calendar.current
        let startOfTomorrow = cal.startOfDay(for: tomorrow)
        let tmStart = calculateAltitudeCrossing(coordinate: coordinate, date: startOfTomorrow, targetAltitude: -4.0, isRising: true, timeZone: timeZone)
        let tmEnd = calculateAltitudeCrossing(coordinate: coordinate, date: startOfTomorrow, targetAltitude: 6.0, isRising: true, timeZone: timeZone)
        return (tmStart, tmEnd, true)
    }
}
