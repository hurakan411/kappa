import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        let _ = languageManager.selectedLanguage // 言語変更を検知してタブバー表記などを即座に再描画させる
        ZStack {
            if hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label(AppTexts.tabHome, systemImage: "drop.fill")
                        }
                        .tag(0)
                    
                    AlbumView(selectedTab: $selectedTab)
                        .tabItem {
                            Label(AppTexts.tabAlbum, systemImage: "book.fill")
                        }
                        .tag(1)
                    
                    LogView()
                        .tabItem {
                            Label(AppTexts.tabLog, systemImage: "chart.bar.fill")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Label(AppTexts.tabSettings, systemImage: "gearshape.fill")
                        }
                        .tag(3)
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
