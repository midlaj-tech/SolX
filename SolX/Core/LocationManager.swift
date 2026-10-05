import Foundation
import CoreLocation
import Combine

/// Manages GPS location, reverse geocoding, and compass heading.
/// Provides seamless fallback and presets for Simulator and remote planning.
public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
    
    public static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Preset coordinates for photography destinations
    public struct PresetLocation: Identifiable, Hashable, Sendable {
        public let id = UUID()
        public let name: String
        public let coordinate: CLLocationCoordinate2D
        public let timeZoneIdentifier: String
        
        public static func == (lhs: PresetLocation, rhs: PresetLocation) -> Bool {
            lhs.name == rhs.name &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }
    }
    
    public static let presets: [PresetLocation] = [
        PresetLocation(name: "Kannur Coast, Kerala", coordinate: CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704), timeZoneIdentifier: "Asia/Kolkata"),
        PresetLocation(name: "Big Sur, California", coordinate: CLLocationCoordinate2D(latitude: 36.2704, longitude: -121.8081), timeZoneIdentifier: "America/Los_Angeles"),
        PresetLocation(name: "Reykjavik, Iceland", coordinate: CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426), timeZoneIdentifier: "Atlantic/Reykjavik"),
        PresetLocation(name: "Santorini, Greece", coordinate: CLLocationCoordinate2D(latitude: 36.3932, longitude: 25.4615), timeZoneIdentifier: "Europe/Athens"),
        PresetLocation(name: "Tokyo, Japan", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), timeZoneIdentifier: "Asia/Tokyo")
    ]
    
    @Published public var currentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 11.8745, longitude: 75.3704)
    @Published public var heading: Double = 0.0 // True North in degrees
    @Published public var locationName: String = "Kannur Coast"
    @Published public var isUsingGPS: Bool = true
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 1.0 // 1 degree updates
        authorizationStatus = locationManager.authorizationStatus
    }
    
    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startTracking() {
        if isUsingGPS {
            locationManager.startUpdatingLocation()
            #if os(iOS) || os(watchOS)
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
            #endif
        }
    }
    
    public func stopTracking() {
        locationManager.stopUpdatingLocation()
        #if os(iOS) || os(watchOS)
        if CLLocationManager.headingAvailable() {
            locationManager.stopUpdatingHeading()
        }
        #endif
    }
    
    public func selectPreset(_ preset: PresetLocation) {
        isUsingGPS = false
        stopTracking()
        currentCoordinate = preset.coordinate
        locationName = preset.name
    }
    
    public func enableLiveGPS() {
        isUsingGPS = true
        requestPermission()
        startTracking()
    }
    
    // MARK: - CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            #if os(iOS) || os(watchOS)
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startTracking()
            }
            #else
            if manager.authorizationStatus == .authorizedAlways {
                self.startTracking()
            }
            #endif
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isUsingGPS, let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentCoordinate = location.coordinate
            self.reverseGeocode(location: location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        DispatchQueue.main.async {
            self.heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, error == nil, let placemark = placemarks?.first else { return }
            let name = [placemark.locality, placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
            DispatchQueue.main.async {
                self.locationName = name.isEmpty ? "Current Location" : name
            }
        }
    }
}
