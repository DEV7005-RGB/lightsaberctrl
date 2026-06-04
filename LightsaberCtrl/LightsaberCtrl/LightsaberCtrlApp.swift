import SwiftUI

@main
struct LightsaberCtrlApp: App {
    @State private var showSplash = false
    @AppStorage("customStartupMediaPath") private var customStartupMediaPath: String = ""
    
    var body: some Scene {
        WindowGroup {
            RootView(showSplash: $showSplash, customStartupMediaPath: customStartupMediaPath)
        }
    }
}

struct RootView: View {
    @Binding var showSplash: Bool
    let customStartupMediaPath: String
    
    var body: some View {
        Group {
            if showSplash {
                SplashView(showSplash: $showSplash)
            } else {
                ContentView()
            }
        }
        .onAppear {
            let hasCustomMedia = !customStartupMediaPath.isEmpty
            if hasCustomMedia {
                showSplash = true
            }
        }
    }
}
