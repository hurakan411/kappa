import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        let _ = languageManager.selectedLanguage // 言語変更を検知してタブバー表記などを即座に再描画させる
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
            for kappa in allKappas {
                SupabaseStorageManager.shared.fetchFileList(for: kappa.id)
            }
        }
    }
}
