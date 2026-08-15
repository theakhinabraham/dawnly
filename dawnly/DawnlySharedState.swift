import Foundation

enum DawnlySharedState {

    private static let suiteName =
        "group.com.akhin.dawnly"

    private static let startDateKey =
        "runningSessionStartDate"

    private static let endDateKey =
        "runningSessionEndDate"

    private static var defaults:
        UserDefaults {

        UserDefaults(
            suiteName: suiteName
        )!
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
    }

    // MARK: - Read

    static func runningSession()
        -> (startDate: Date, endDate: Date)? {

        guard
            let startDate =
                defaults.object(
                    forKey: startDateKey
                ) as? Date,

            let endDate =
                defaults.object(
                    forKey: endDateKey
                ) as? Date
        else {
            return nil
        }

        // Automatically treat an expired session
        // as no longer running.
        if endDate <= Date() {

            clearRunningSession()

            return nil
        }

        return (
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Clear

    static func clearRunningSession() {

        defaults.removeObject(
            forKey: startDateKey
        )

        defaults.removeObject(
            forKey: endDateKey
        )
    }
}
