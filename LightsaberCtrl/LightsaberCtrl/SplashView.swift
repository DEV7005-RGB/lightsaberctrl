import SwiftUI
import AVKit
import AVFoundation

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var dismissTimer: Timer?
    @Binding var showSplash: Bool
    
    @AppStorage("customStartupMediaPath") private var customStartupMediaPath: String = ""
    @AppStorage("startupMediaAspectMode") private var startupMediaAspectMode: Int = 0
    @AppStorage("startupVideoDuration") private var startupVideoDuration: Int = 3
    
    private var isVideo: Bool {
        customStartupMediaPath.contains("startup_video")
    }
    
    private var customMediaURL: URL? {
        guard !customStartupMediaPath.isEmpty else { return nil }
        return URL(string: customStartupMediaPath)
    }
    
    private var customImage: UIImage? {
        guard let url = customMediaURL, !isVideo,
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let url = customMediaURL {
                    if isVideo {
                        VideoPlayerView(
                            url: url,
                            aspectMode: startupMediaAspectMode,
                            duration: startupVideoDuration,
                            onComplete: {
                                withAnimation(.easeOut(duration: 0.8)) {
                                    opacity = 0.0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    showSplash = false
                                }
                            }
                        )
                        .edgesIgnoringSafeArea(.all)
                        .opacity(opacity)
                    } else if let image = customImage {
                        AutoAspectImage(image: image, aspectMode: startupMediaAspectMode)
                            .edgesIgnoringSafeArea(.all)
                            .opacity(opacity)
                    } else {
                        defaultSplashContent(geometry: geometry)
                    }
                } else {
                    defaultSplashContent(geometry: geometry)
                }
            }
            .statusBar(hidden: true)
            .onAppear {
                setupSplash()
            }
            .onDisappear {
                dismissTimer?.invalidate()
                dismissTimer = nil
            }
        }
    }
    
    private func setupSplash() {
        if customMediaURL == nil {
            startDefaultAnimation()
        } else {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
            
            if !isVideo {
                dismissTimer = Timer.scheduledTimer(withTimeInterval: Double(startupVideoDuration), repeats: false) { _ in
                    withAnimation(.easeOut(duration: 0.8)) {
                        opacity = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showSplash = false
                    }
                }
            }
        }
    }
    
    private func startDefaultAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }
        
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotation = 360.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 0.5
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showSplash = false
            }
        }
    }
    
    @ViewBuilder
    private func defaultSplashContent(geometry: GeometryProxy) -> some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        LinearGradient(gradient: Gradient(colors: [
            Color(red: 0.02, green: 0.02, blue: 0.05),
            Color(red: 0.05, green: 0.05, blue: 0.1)
        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
        
        Circle()
            .fill(goldColor.opacity(0.1))
            .frame(width: 300, height: 300)
            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
            .scaleEffect(scale)
        
        Circle()
            .fill(goldColor.opacity(0.08))
            .frame(width: 200, height: 200)
            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
            .scaleEffect(scale)
        
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(goldColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                
                Circle()
                    .stroke(goldColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .scaleEffect(scale)
                
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: goldColor.opacity(0.6), radius: 15, x: 0, y: 0)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
            }
            
            Text("Lightsaber Ctrl")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: goldColor.opacity(0.5), radius: 10)
                .opacity(opacity)
            
            Text("Ultimate Lightsaber Control")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                .opacity(opacity)
        }
    }
}

struct AutoAspectImage: View {
    let image: UIImage
    let aspectMode: Int
    
    private var imageAspectRatio: CGFloat? {
        guard image.size.height > 0 else { return nil }
        return image.size.width / image.size.height
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenAspectRatio = geometry.size.width / geometry.size.height
            let imgRatio = imageAspectRatio
            let shouldCrop = imgRatio != nil && abs(imgRatio! - screenAspectRatio) < 0.1
            
            if shouldCrop || aspectMode == 0 {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    let aspectMode: Int
    let duration: Int
    let onComplete: () -> Void
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.showsPlaybackControls = false
        
        controller.videoGravity = aspectMode == 0 ? .resizeAspectFill : .resizeAspect
        
        player.play()
        
        context.coordinator.duration = duration
        context.coordinator.onComplete = onComplete
        context.coordinator.startTimer()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.videoGravity = aspectMode == 0 ? .resizeAspectFill : .resizeAspect
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var duration: Int = 3
        var onComplete: (() -> Void)?
        private var timer: Timer?
        
        func startTimer() {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: Double(duration), repeats: false) { [weak self] _ in
                self?.onComplete?()
            }
        }
        
        func invalidate() {
            timer?.invalidate()
            timer = nil
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(showSplash: .constant(true))
            .preferredColorScheme(.dark)
    }
}
