import Foundation

enum DawnlySharedState {

    // MARK: - App Group

    private static let suiteName =
        "group.com.akhin.dawnly"

    // MARK: - Keys

    private static let startDateKey =
        "runningSessionStartDate"

    private static let endDateKey =
        "runningSessionEndDate"

    // MARK: - UserDefaults

    private static var defaults: UserDefaults {

        guard let defaults = UserDefaults(
            suiteName: suiteName
        ) else {

            fatalError(
                "Could not access Dawnly App Group: \(suiteName)"
            )
        }

        return defaults
    }

    // MARK: - Running Session

    struct RunningSession {

        let startDate: Date
        let endDate: Date

        var duration: TimeInterval {
            endDate.timeIntervalSince(startDate)
        }

        var timeRemaining: TimeInterval {
            max(
                0,
                endDate.timeIntervalSinceNow
            )
        }

        var isRunning: Bool {
            endDate > Date()
        }
    }

    // MARK: - Save

    static func saveRunningSession(
        startDate: Date,
        endDate: Date
    ) {

        defaults.set(
            startDate,
            forKey: startDateKey
        )

        defaults.set(
            endDate,
            forKey: endDateKey
        )

        defaults.synchronize()
    }

    // MARK: - Read

    static func runningSession()
        -> RunningSession? {

        guard
            let startDate = defaults.object(
                forKey: startDateKey
            ) as? Date,

            let endDate = defaults.object(
                forKey: endDateKey
            ) as? Date
        else {

            return nil
        }

        // If the timer has expired,
        // remove the stale shared state.

        guard endDate > Date() else {

            clearRunningSession()

            return nil
        }

        return RunningSession(
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Is Running

    static var isRunning: Bool {

        runningSession() != nil
    }

    // MARK: - Clear

    static func clearRunningSession() {

        defaults.removeObject(
            forKey: startDateKey
        )

        defaults.removeObject(
            forKey: endDateKey
        )

        defaults.synchronize()
    }
}
