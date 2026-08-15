import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {

        TabView {

            HomeView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FocusSession.self)
}
