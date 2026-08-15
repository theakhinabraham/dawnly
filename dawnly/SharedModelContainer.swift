import Foundation
import SwiftData

enum SharedModelContainer {

    static let appGroupIdentifier =
        "group.com.akhin.dawnly"

    static let container: ModelContainer = {

        let schema = Schema([
            FocusSession.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(
                appGroupIdentifier
            )
        )

        do {

            return try ModelContainer(
                for: schema,
                configurations: [
                    configuration
                ]
            )

        } catch {

            fatalError(
                "Could not create ModelContainer: \(error)"
            )
        }
    }()
}
