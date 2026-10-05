import SwiftUI
import Combine

/// ThemeManager manages Light and Dark mode switching for SolX.
/// Provides synchronized color palettes, glass materials, and specular borders.
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @AppStorage("solx_is_dark_mode") public var isDarkMode: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    private init() {}
    
    public func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isDarkMode.toggle()
        }
    }
    
    // MARK: - Dynamic Design Tokens
    public var preferredColorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    public var cardBackground: Material {
        isDarkMode ? .ultraThinMaterial : .regularMaterial
    }
    
    public var cardOverlayColor: Color {
        isDarkMode ? Color.black.opacity(0.35) : Color.white.opacity(0.65)
    }
    
    public var cardBorderColor: Color {
        isDarkMode ? Color.white.opacity(0.18) : Color.black.opacity(0.08)
    }
    
    public var primaryText: Color {
        isDarkMode ? Color.white : Color(red: 0.10, green: 0.12, blue: 0.16)
    }
    
    public var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.70) : Color.black.opacity(0.60)
    }
    
    public var tertiaryText: Color {
        isDarkMode ? Color.white.opacity(0.45) : Color.black.opacity(0.40)
    }
    
    public var compassDialBackground: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    public var compassDialTrack: Color {
        isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.12)
    }
    
    // Golden Hour Accent
    public var goldenAccent: Color {
        Color(red: 0.98, green: 0.72, blue: 0.15)
    }
    
    // Blue Hour Accent
    public var blueHourAccent: Color {
        Color(red: 0.22, green: 0.47, blue: 0.88)
    }
    
    public var specularHighlight: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color.white.opacity(0.35), Color.white.opacity(0.05), Color.clear]
                : [Color.white.opacity(0.80), Color.white.opacity(0.20), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
