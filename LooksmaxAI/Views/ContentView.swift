import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserStats]

    @State private var showOnboarding = false

    var body: some View {
        Group {
            if users.isEmpty || showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
            } else {
                MainTabView()
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Lab", systemImage: "waveform.path.ecg")
                }
                .tag(0)

            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "faceid")
                }
                .tag(1)

            RoutineListView()
                .tabItem {
                    Label("Routines", systemImage: "list.bullet.clipboard")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(3)
        }
        .tint(DesignSystem.Colors.accentCyan)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [UserStats.self, FaceMetrics.self, ScanHistory.self, Recommendation.self], inMemory: true)
}
