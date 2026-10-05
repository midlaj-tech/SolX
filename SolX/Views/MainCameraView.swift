import SwiftUI

/// MainCameraView: Primary iPhone & iPad photography interface.
/// Exactly reproduces the layout, cards, and aesthetic of the SolX portfolio screenshot.
public struct MainCameraView: View {
    @ObservedObject var engine = SolarEphemerisEngine.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var camera = CameraService.shared
    @ObservedObject var theme = ThemeManager.shared
    
    @State private var showTrajectoryMap = false
    @State private var showSettings = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Live Viewfinder Feed / Coastal Wallpaper Fallback
            CameraViewfinderRepresentable()
            
            // 2. Composition Grid Overlay (Rule of Thirds, Golden Ratio, etc.)
            CompositionGridView(mode: camera.gridMode)
            
            // 3. Shutter Flash Feedback
            if camera.showCaptureFlash {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
            
            // 4. Main HUD Interface Elements
            VStack(spacing: 0) {
                // Top Header Bar
                HStack(alignment: .top) {
                    // Quick Light / Dark Theme Toggle Pill
                    Button(action: {
                        theme.toggleTheme()
                        HapticService.trigger(.light)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(theme.isDarkMode ? "DARK" : "LIGHT")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(theme.cardBorderColor, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    
                    Spacer()
                    
                    // Central Title & Status
                    VStack(spacing: 2) {
                        Text("SolX • Golden Hour")
                            .font(.system(size: 17, weight: .semibold, design: .default))
                            .foregroundColor(Color.white)
                            .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)
                        
                        Text(locationManager.locationName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 1)
                    }
                    
                    Spacer()
                    
                    // GPS Status Pill
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.2, green: 0.85, blue: 0.45))
                            .frame(width: 6, height: 6)
                        Text(locationManager.isUsingGPS ? "GPS" : "PRESET")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                // Top Left: Floating Sun Angle Compass Card
                HStack {
                    SunAngleCompassCard()
                        .padding(.leading, 18)
                        .padding(.top, 16)
                    Spacer()
                }
                
                Spacer()
                
                // Bottom Stack: Ephemeris Timeline Card + Camera Controls Dock
                VStack(spacing: 12) {
                    EphemerisTimelineCard()
                        .padding(.horizontal, 18)
                    
                    CameraControlsToolbar(
                        showTrajectoryMap: $showTrajectoryMap,
                        showSettings: $showSettings
                    )
                }
                .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $showTrajectoryMap) {
            SolarTrajectoryMapView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
        .preferredColorScheme(theme.preferredColorScheme)
        .onAppear {
            locationManager.startTracking()
        }
    }
}
