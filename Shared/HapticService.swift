import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum HapticStyle: Sendable {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

public struct HapticService: Sendable {
    public static func trigger(_ style: HapticStyle) {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            switch style {
            case .light:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            case .medium:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            case .heavy:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.prepare()
                generator.impactOccurred()
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        #endif
    }
}
