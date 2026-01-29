import SwiftUI
import SwiftData

@main
struct LooksmaxAIApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserStats.self,
            FaceMetrics.self,
            ScanHistory.self,
            Recommendation.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
