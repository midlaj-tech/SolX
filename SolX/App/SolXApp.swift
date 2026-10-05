import SwiftUI

@main
struct SolXApp: App {
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var engine = SolarEphemerisEngine.shared
    @StateObject private var locationManager = LocationManager.shared
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some Scene {
        WindowGroup {
            Group {
                if horizontalSizeClass == .regular {
                    iPadLayoutView()
                } else {
                    MainCameraView()
                }
            }
            .preferredColorScheme(theme.preferredColorScheme)
        }
    }
}
