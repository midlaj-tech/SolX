import Foundation
import CoreLocation
import Combine
import SwiftUI

/// SolarEphemerisEngine provides continuous real-time astronomical calculation updates,
/// countdown tracking, and interactive time-travel scrubbing.
public final class SolarEphemerisEngine: ObservableObject {
    public static let shared = SolarEphemerisEngine()
    
    private let math = SolarMath.shared
    private var timerCancellable: AnyCancellable?
    private var locationCancellables = Set<AnyCancellable>()
    
    @ObservedObject private var locationManager = LocationManager.shared
    
    @Published public var snapshot: SolarSnapshot
    @Published public var simulatedDate: Date? = nil
    @Published public var isScrubbing: Bool = false
    
    private init() {
        let initialCoord = LocationManager.shared.currentCoordinate
        self.snapshot = math.createSnapshot(coordinate: initialCoord, date: Date())
        
        setupBindings()
        startLiveTimer()
    }
    
    private func setupBindings() {
        locationManager.$currentCoordinate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coord in
                self?.recalculate(coordinate: coord)
            }
            .store(in: &locationCancellables)
    }
    
    public func startLiveTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self = self, !self.isScrubbing else { return }
                self.recalculate(date: now)
            }
    }
    
    public func recalculate(coordinate: CLLocationCoordinate2D? = nil, date: Date? = nil) {
        let coord = coordinate ?? locationManager.currentCoordinate
        let targetDate = date ?? simulatedDate ?? Date()
        self.snapshot = math.createSnapshot(coordinate: coord, date: targetDate)
    }
    
    // MARK: - Time Travel Scrubbing
    public func beginScrubbing() {
        isScrubbing = true
    }
    
    public func scrubTo(fractionOfDay fraction: Double) {
        let cal = Calendar.current
        let baseDate = Date()
        let startOfDay = cal.startOfDay(for: baseDate)
        let totalSecondsInDay: Double = 86400.0
        let targetDate = startOfDay.addingTimeInterval(max(0, min(totalSecondsInDay - 1, fraction * totalSecondsInDay)))
        self.simulatedDate = targetDate
        recalculate(date: targetDate)
    }
    
    public func resetToLiveTime() {
        isScrubbing = false
        simulatedDate = nil
        recalculate(date: Date())
    }
}
