import SwiftUI

/// iPadLayoutView: Expansive multi-column console layout optimized for iPadOS.
/// Splits the high-resolution camera viewfinder and astronomical telemetry console.
public struct iPadLayoutView: View {
    @ObservedObject var engine = SolarEphemerisEngine.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var camera = CameraService.shared
    @ObservedObject var theme = ThemeManager.shared
    
    @State private var showTrajectoryMap = false
    @State private var showSettings = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left: High-Res Camera Viewfinder with overlay tools
            ZStack {
                CameraViewfinderRepresentable()
                CompositionGridView(mode: camera.gridMode)
                
                // Top floating pill with location
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SolX • Golden Hour")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text(locationManager.locationName)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        
                        Spacer()
                    }
                    .padding(24)
                    
                    Spacer()
                    
                    // Floating camera toolbar
                    CameraControlsToolbar(
                        showTrajectoryMap: $showTrajectoryMap,
                        showSettings: $showSettings
                    )
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Right: Ephemeris & Telemetry Console Panel
            VStack(spacing: 20) {
                // Header & Theme Switch
                HStack {
                    Text("Solar Telemetry")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        theme.toggleTheme()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                            Text(theme.isDarkMode ? "Dark" : "Light")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.cardBackground)
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                // Sun Angle Compass Card (Prominent display on iPad)
                SunAngleCompassCard()
                    .scaleEffect(1.08)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                
                // Ephemeris Timeline
                EphemerisTimelineCard()
                    .padding(.horizontal, 20)
                
                // Extra iPad Telemetry Strip
                VStack(spacing: 12) {
                    HStack {
                        DetailMetricBox(title: "Solar Altitude", value: engine.snapshot.altitudeString, subtitle: "Current Angle")
                        DetailMetricBox(title: "Solar Azimuth", value: engine.snapshot.azimuthCompassString, subtitle: "Bearing from North")
                    }
                    HStack {
                        DetailMetricBox(title: "Golden Hour", value: engine.snapshot.countdownFormatted, subtitle: "Next Countdown", isAccent: true)
                        DetailMetricBox(title: "Solar Phase", value: engine.snapshot.currentPhase.displayName, subtitle: "Lighting Mode")
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(width: 380)
            .background(theme.cardBackground)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(theme.cardBorderColor),
                alignment: .leading
            )
        }
        .sheet(isPresented: $showTrajectoryMap) {
            SolarTrajectoryMapView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
    }
}

private struct DetailMetricBox: View {
    let title: String
    let value: String
    let subtitle: String
    var isAccent: Bool = false
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(theme.secondaryText)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isAccent ? theme.goldenAccent : theme.primaryText)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(theme.tertiaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.compassDialBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.cardBorderColor, lineWidth: 1))
    }
}
