import SwiftUI

/// CompositionGridView: Overlays rule of thirds, golden ratio, or center crosshairs onto the viewfinder.
public struct CompositionGridView: View {
    let mode: CompositionGrid
    
    public init(mode: CompositionGrid) {
        self.mode = mode
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            switch mode {
            case .ruleOfThirds:
                Path { p in
                    // Vertical lines
                    p.move(to: CGPoint(x: w / 3.0, y: 0))
                    p.addLine(to: CGPoint(x: w / 3.0, y: h))
                    p.move(to: CGPoint(x: 2.0 * w / 3.0, y: 0))
                    p.addLine(to: CGPoint(x: 2.0 * w / 3.0, y: h))
                    
                    // Horizontal lines
                    p.move(to: CGPoint(x: 0, y: h / 3.0))
                    p.addLine(to: CGPoint(x: w, y: h / 3.0))
                    p.move(to: CGPoint(x: 0, y: 2.0 * h / 3.0))
                    p.addLine(to: CGPoint(x: w, y: 2.0 * h / 3.0))
                }
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
                
            case .goldenRatio:
                let phi: CGFloat = 0.61803398875
                let invPhi: CGFloat = 1.0 - phi
                Path { p in
                    p.move(to: CGPoint(x: w * invPhi, y: 0))
                    p.addLine(to: CGPoint(x: w * invPhi, y: h))
                    p.move(to: CGPoint(x: w * phi, y: 0))
                    p.addLine(to: CGPoint(x: w * phi, y: h))
                    
                    p.move(to: CGPoint(x: 0, y: h * invPhi))
                    p.addLine(to: CGPoint(x: w, y: h * invPhi))
                    p.move(to: CGPoint(x: 0, y: h * phi))
                    p.addLine(to: CGPoint(x: w, y: h * phi))
                }
                .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
            case .centerCross:
                Path { p in
                    let cx = w / 2.0
                    let cy = h / 2.0
                    let len: CGFloat = 24.0
                    
                    p.move(to: CGPoint(x: cx - len, y: cy))
                    p.addLine(to: CGPoint(x: cx + len, y: cy))
                    p.move(to: CGPoint(x: cx, y: cy - len))
                    p.addLine(to: CGPoint(x: cx, y: cy + len))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                
            case .off:
                EmptyView()
            }
        }
        .allowsHitTesting(false)
    }
}
