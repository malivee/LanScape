import SwiftUI

@main
struct LanScapeApp: App {
    init() {
        AppPreloadService.shared.preloadAll()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppPreloadService.shared.preloadAll()
                }
        }
    }
}
