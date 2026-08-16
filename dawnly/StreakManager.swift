import Foundation
import SwiftData

// MARK: - Streak Statistics

struct StreakStatistics {

    /// Number of consecutive days ending today that contain
    /// at least one completed focus session.
    let currentStreak: Int

    /// The highest number of consecutive focus days
    /// found in the user's history.
    let longestStreak: Int

    /// Number of days with at least one completed session.
    let totalFocusedDays: Int

    /// Number of completed sessions today.
    let sessionsToday: Int

    /// Whether today contains at least one completed session.
    let focusedToday: Bool
}

// MARK: - Streak Manager

struct StreakManager {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Public API

    /// Calculates all streak statistics from completed SwiftData sessions.
    ///
    /// A day counts as a focused day when it contains at least one
    /// completed FocusSession.
    func calculate(
        sessions: [FocusSession],
        referenceDate: Date = Date()
    ) -> StreakStatistics {

        let completedSessions = sessions.filter {
            $0.completed
        }

        let focusedDays = uniqueFocusedDays(
            from: completedSessions
        )

        let today = calendar.startOfDay(
            for: referenceDate
        )

        let focusedToday = focusedDays.contains(today)

        let sessionsToday = completedSessions.filter {
            calendar.isDate(
                $0.startDate,
                inSameDayAs: referenceDate
            )
        }.count

        let currentStreak = calculateCurrentStreak(
            focusedDays: focusedDays,
            today: today
        )

        let longestStreak = calculateLongestStreak(
            focusedDays: focusedDays
        )

        return StreakStatistics(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalFocusedDays: focusedDays.count,
            sessionsToday: sessionsToday,
            focusedToday: focusedToday
        )
    }

    // MARK: - Focused Days

    private func uniqueFocusedDays(
        from sessions: [FocusSession]
    ) -> Set<Date> {

        var days = Set<Date>()

        for session in sessions {

            let day = calendar.startOfDay(
                for: session.startDate
            )

            days.insert(day)
        }

        return days
    }

    // MARK: - Current Streak

    private func calculateCurrentStreak(
        focusedDays: Set<Date>,
        today: Date
    ) -> Int {

        guard !focusedDays.isEmpty else {
            return 0
        }

        var currentDay = today
        var streak = 0

        // If the user has not focused today, allow the streak
        // to continue from yesterday. This means the user can
        // open the app during the day without immediately seeing
        // a broken streak.
        if !focusedDays.contains(currentDay) {

            guard let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: currentDay
            ) else {
                return 0
            }

            currentDay = yesterday
        }

        while focusedDays.contains(currentDay) {

            streak += 1

            guard let previousDay = calendar.date(
                byAdding: .day,
                value: -1,
                to: currentDay
            ) else {
                break
            }

            currentDay = previousDay
        }

        return streak
    }

    // MARK: - Longest Streak

    private func calculateLongestStreak(
        focusedDays: Set<Date>
    ) -> Int {

        guard !focusedDays.isEmpty else {
            return 0
        }

        let sortedDays = focusedDays.sorted()

        var longestStreak = 1
        var currentStreak = 1

        for index in 1..<sortedDays.count {

            let previousDay = sortedDays[index - 1]
            let currentDay = sortedDays[index]

            guard let expectedNextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: previousDay
            ) else {
                continue
            }

            if calendar.isDate(
                expectedNextDay,
                inSameDayAs: currentDay
            ) {

                currentStreak += 1

                longestStreak = max(
                    longestStreak,
                    currentStreak
                )

            } else {

                currentStreak = 1
            }
        }

        return longestStreak
    }
}
