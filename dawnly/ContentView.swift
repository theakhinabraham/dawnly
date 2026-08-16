import SwiftUI
import SwiftData

struct ContentView: View {

    @AppStorage("appearance")
    private var appearance = "system"

    var body: some View {

        TabView {

            HomeView()
                .tabItem {
                    Label(
                        "Focus",
                        systemImage: "timer"
                    )
                }

            HistoryView()
                .tabItem {
                    Label(
                        "History",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
            StreakView()
                .tabItem {
                    Label(
                        "Streak",
                        systemImage: "flame.fill"
                    )
                }
            StatisticsView()
                .tabItem {
                    Label(
                        "Statistics",
                        systemImage: "chart.bar.fill"
                    )
                }

            SettingsView()
                .tabItem {
                    Label(
                        "Settings",
                        systemImage: "gearshape.fill"
                    )
                }
        }
        .preferredColorScheme(
            selectedColorScheme
        )
    }

    // MARK: - Appearance

    private var selectedColorScheme: ColorScheme? {

        switch appearance {

        case "light":
            return .light

        case "dark":
            return .dark

        default:
            return nil
        }
    }
}

#Preview {

    ContentView()
        .modelContainer(
            for: FocusSession.self
        )
}
