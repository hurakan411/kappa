import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                TabView {
                    HomeView()
                        .id(languageManager.selectedLanguage)
                        .tabItem {
                            Label(AppTexts.tabHome, systemImage: "drop.fill")
                        }
                    
                    AlbumView()
                        .id(languageManager.selectedLanguage)
                        .tabItem {
                            Label(AppTexts.tabAlbum, systemImage: "book.fill")
                        }
                    
                    LogView()
                        .id(languageManager.selectedLanguage)
                        .tabItem {
                            Label(AppTexts.tabLog, systemImage: "chart.bar.fill")
                        }
                    
                    SettingsView()
                        .id(languageManager.selectedLanguage)
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
            for kappa in allKappas {
                SupabaseStorageManager.shared.fetchFileList(for: kappa.id)
            }
        }
    }
}
