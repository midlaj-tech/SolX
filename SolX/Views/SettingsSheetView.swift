import SwiftUI

/// SettingsSheetView: Allows changing themes, selecting photography locations, and configuring camera tools.
public struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var camera = CameraService.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Theme Section (Explicit User Requirement)
                Section(header: Text("Appearance & Theme")) {
                    HStack {
                        Label {
                            Text(theme.isDarkMode ? "Dark Theme (Liquid Glass)" : "Light Theme (Crystal Glass)")
                                .font(.system(size: 15, weight: .medium))
                        } icon: {
                            Image(systemName: theme.isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                                .foregroundColor(theme.goldenAccent)
                        }
                        
                        Spacer()
                        
                        // Apple iOS standard Toggle Switch
                        Toggle("", isOn: Binding(
                            get: { theme.isDarkMode },
                            set: { _ in theme.toggleTheme() }
                        ))
                        .labelsHidden()
                        .tint(theme.goldenAccent)
                    }
                }
                
                // MARK: - GPS & Location Section
                Section(header: Text("Photography Location")) {
                    Toggle("Use Live GPS", isOn: Binding(
                        get: { locationManager.isUsingGPS },
                        set: { enable in
                            if enable {
                                locationManager.enableLiveGPS()
                            } else {
                                if let first = LocationManager.presets.first {
                                    locationManager.selectPreset(first)
                                }
                            }
                        }
                    ))
                    .tint(theme.goldenAccent)
                    
                    if !locationManager.isUsingGPS {
                        Picker("Preset Location", selection: Binding(
                            get: {
                                LocationManager.presets.first(where: {
                                    abs($0.coordinate.latitude - locationManager.currentCoordinate.latitude) < 0.001
                                }) ?? LocationManager.presets[0]
                            },
                            set: { newPreset in
                                locationManager.selectPreset(newPreset)
                            }
                        )) {
                            ForEach(LocationManager.presets) { preset in
                                Text(preset.name).tag(preset)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Active Coordinates")
                            .foregroundColor(theme.secondaryText)
                        Spacer()
                        Text(String(format: "%.4f°, %.4f°", locationManager.currentCoordinate.latitude, locationManager.currentCoordinate.longitude))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(theme.primaryText)
                    }
                }
                
                // MARK: - Camera & Composition Grid
                Section(header: Text("Composition Guides")) {
                    Picker("Grid Overlay", selection: $camera.gridMode) {
                        ForEach(CompositionGrid.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - SolX Architecture & About
                Section(header: Text("About SolX")) {
                    HStack {
                        Text("Engine")
                        Spacer()
                        Text("NOAA On-Device Spherical Math")
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    HStack {
                        Text("Accuracy")
                        Spacer()
                        Text("±0.01° Azimuth & Altitude")
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    HStack {
                        Text("Network Dependency")
                        Spacer()
                        Text("100% Offline via CoreLocation")
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
            .navigationTitle("SolX Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.goldenAccent)
                }
            }
        }
        .preferredColorScheme(theme.preferredColorScheme)
    }
}
