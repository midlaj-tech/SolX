import SwiftUI

/// CameraControlsToolbar: Bottom glass floating dock with shutter, grid, torch, map, and settings dial.
public struct CameraControlsToolbar: View {
    @ObservedObject var camera = CameraService.shared
    @ObservedObject var theme = ThemeManager.shared
    
    @Binding var showTrajectoryMap: Bool
    @Binding var showSettings: Bool
    
    public init(showTrajectoryMap: Binding<Bool>, showSettings: Binding<Bool>) {
        self._showTrajectoryMap = showTrajectoryMap
        self._showSettings = showSettings
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // 1. Grid Mode Toggle
            Button(action: {
                camera.cycleGrid()
            }) {
                Image(systemName: camera.gridMode.iconName)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(camera.gridMode == .off ? theme.secondaryText : theme.primaryText)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity)
            
            // 2. Torch / Flash Toggle
            Button(action: {
                camera.toggleTorch()
                HapticService.trigger(.light)
            }) {
                Image(systemName: camera.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(camera.isTorchOn ? theme.goldenAccent : theme.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity)
            
            // 3. Center Shutter Button
            Button(action: {
                camera.takePhoto()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 3.5)
                        .frame(width: 66, height: 66)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 4. Solar Trajectory Map Trigger
            Button(action: {
                showTrajectoryMap = true
                HapticService.trigger(.light)
            }) {
                Image(systemName: "map")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(theme.primaryText)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity)
            
            // 5. Settings / Theme Dial
            Button(action: {
                showSettings = true
                HapticService.trigger(.light)
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(theme.primaryText)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(theme.cardBorderColor, lineWidth: 1)
                )
                .overlay(
                    theme.specularHighlight
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                )
        )
        .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.5 : 0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
}
