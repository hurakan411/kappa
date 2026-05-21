import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
        .onAppear {
            SupabaseStorageManager.shared.fetchFileList(for: "gamer")
        }
    }
}
