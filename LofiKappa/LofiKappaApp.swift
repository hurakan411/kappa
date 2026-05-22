import SwiftUI
import SwiftData

@main
struct LofiKappaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(SharedDatabase.container)
    }
}
