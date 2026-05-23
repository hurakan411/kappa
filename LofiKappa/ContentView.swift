import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                TabView {
                    HomeView()
                        .tabItem {
                            Label(AppTexts.tabHome, systemImage: "drop.fill")
                        }
                    
                    AlbumView()
                        .tabItem {
                            Label(AppTexts.tabAlbum, systemImage: "book.fill")
                        }
                    
                    LogView()
                        .tabItem {
                            Label(AppTexts.tabLog, systemImage: "chart.bar.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label(AppTexts.tabSettings, systemImage: "gearshape.fill")
                        }
                }
                .tint(Theme.Colors.primaryBlue)
                .font(.system(.body, design: .rounded))
                .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: hasCompletedOnboarding)
        .onAppear {
            SupabaseStorageManager.shared.fetchFileList(for: "gamer")
        }
    }
}
