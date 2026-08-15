import SwiftUI
import SwiftData

@main
struct DawnlyApp: App {

    init() {

        Task {
            await NotificationManager.shared
                .requestPermission()
        }
    }

    var body: some Scene {

        WindowGroup {
            ContentView()
        }
        .modelContainer(
            SharedModelContainer.container
        )
    }
}   
