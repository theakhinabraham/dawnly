import Foundation
import SwiftData

@MainActor
final class StatisticsManager {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Today's Sessions

    func todaysSessions() -> [FocusSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.completed &&
                session.startDate >= startOfDay
            },
            sortBy: [
                SortDescriptor(\.startDate, order: .forward)
            ]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Statistics fetch error: \(error)")
            return []
        }
    }

    // MARK: - This Week

    func thisWeeksSessions() -> [FocusSession] {
        let calendar = Calendar.current

        guard let startOfWeek = calendar.dateInterval(
            of: .weekOfYear,
            for: Date()
        )?.start else {
            return []
        }

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.completed &&
                session.startDate >= startOfWeek
            },
            sortBy: [
                SortDescriptor(\.startDate, order: .forward)
            ]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Statistics fetch error: \(error)")
            return []
        }
    }

    // MARK: - This Month

    func thisMonthsSessions() -> [FocusSession] {
        let calendar = Calendar.current

        guard let startOfMonth = calendar.dateInterval(
            of: .month,
            for: Date()
        )?.start else {
            return []
        }

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.completed &&
                session.startDate >= startOfMonth
            },
            sortBy: [
                SortDescriptor(\.startDate, order: .forward)
            ]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Statistics fetch error: \(error)")
            return []
        }
    }

    // MARK: - Focus Time

    func totalFocusTime(
        sessions: [FocusSession]
    ) -> TimeInterval {

        sessions.reduce(0) {
            $0 + $1.duration
        }
    }

    // MARK: - Session Count

    func sessionCount(
        sessions: [FocusSession]
    ) -> Int {

        sessions.count
    }

    // MARK: - Average Session

    func averageSessionDuration(
        sessions: [FocusSession]
    ) -> TimeInterval {

        guard !sessions.isEmpty else {
            return 0
        }

        return totalFocusTime(
            sessions: sessions
        ) / Double(sessions.count)
    }

    // MARK: - Longest Session

    func longestSession(
        sessions: [FocusSession]
    ) -> TimeInterval {

        sessions.map(\.duration).max() ?? 0
    }

    // MARK: - Daily Breakdown

    func dailyFocusTime(
        sessions: [FocusSession]
    ) -> [Date: TimeInterval] {

        let calendar = Calendar.current

        var result: [Date: TimeInterval] = [:]

        for session in sessions {

            let day = calendar.startOfDay(
                for: session.startDate
            )

            result[day, default: 0] += session.duration
        }

        return result
    }

    // MARK: - Current Streak

    func currentFocusStreak() -> Int {

        let calendar = Calendar.current

        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.completed
            },
            sortBy: [
                SortDescriptor(\.startDate, order: .reverse)
            ]
        )

        let sessions: [FocusSession]

        do {
            sessions = try context.fetch(descriptor)
        } catch {
            print("Statistics streak error: \(error)")
            return 0
        }

        guard !sessions.isEmpty else {
            return 0
        }

        let focusedDays = Set(
            sessions.map {
                calendar.startOfDay(
                    for: $0.startDate
                )
            }
        )

        var streak = 0
        var currentDay = calendar.startOfDay(
            for: Date()
        )

        // If there was no focus today,
        // allow the streak to begin yesterday.
        if !focusedDays.contains(currentDay) {

            guard let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: currentDay
            ) else {
                return 0
            }

            if focusedDays.contains(yesterday) {
                currentDay = yesterday
            } else {
                return 0
            }
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

    // MARK: - Formatting

    func formattedDuration(
        _ duration: TimeInterval
    ) -> String {

        let totalMinutes = Int(duration / 60)

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {

            if minutes == 0 {
                return "\(hours)h"
            }

            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}
