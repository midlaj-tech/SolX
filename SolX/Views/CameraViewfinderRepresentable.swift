import SwiftUI
import AVFoundation

/// CameraViewfinderRepresentable: Live AVFoundation viewfinder for physical devices,
/// seamlessly backing up with high-definition coastal wallpaper in Simulator.
public struct CameraViewfinderRepresentable: View {
    @ObservedObject var camera = CameraService.shared
    @ObservedObject var engine = SolarEphemerisEngine.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            #if !targetEnvironment(simulator)
            if camera.isCameraAvailable {
                CameraPreviewView(session: camera.captureSession)
                    .edgesIgnoringSafeArea(.all)
            } else {
                SimulatedViewfinderBackground()
            }
            #else
            SimulatedViewfinderBackground()
            #endif
            
            // Subtle dynamic solar atmospheric wash based on time of day / scrubbing
            let phase = engine.snapshot.currentPhase
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            phase.color.opacity(phase.isGolden ? 0.15 : (phase.isBlue ? 0.20 : 0.05)),
                            Color.black.opacity(phase == .night ? 0.55 : 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)
        }
    }
}

private struct SimulatedViewfinderBackground: View {
    var body: some View {
        GeometryReader { geo in
            Image("CoastalWallpaper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#if !targetEnvironment(simulator)
private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
#endif
