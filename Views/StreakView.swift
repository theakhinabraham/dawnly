import SwiftUI
import SwiftData

// MARK: - Streak View

struct StreakView: View {

    @Query(
        filter: #Predicate<FocusSession> {
            $0.completed
        },
        sort: \FocusSession.startDate,
        order: .forward
    )
    private var completedSessions: [FocusSession]

    private var statistics: StreakStatistics {

        StreakManager().calculate(
            sessions: completedSessions
        )
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                // MARK: Header

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text("Streaks")
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text(
                        "Build consistency, one focused day at a time."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // MARK: Current Streak

                currentStreakCard

                // MARK: Statistics

                HStack(spacing: 12) {

                    streakMetric(
                        title: "Longest",
                        value:
                            "\(statistics.longestStreak)",
                        subtitle: "days",
                        icon: "flame.fill"
                    )

                    streakMetric(
                        title: "Focused",
                        value:
                            "\(statistics.totalFocusedDays)",
                        subtitle: "days",
                        icon: "calendar"
                    )
                }

                // MARK: Activity Calendar

                activityCalendarCard

                // MARK: Today

                todayCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .background(
            Color(
                .systemGroupedBackground
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Streaks")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Streak Card

    private var currentStreakCard: some View {

        VStack(spacing: 12) {

            Image(
                systemName:
                    statistics.currentStreak > 0
                    ? "flame.fill"
                    : "flame"
            )
            .font(
                .system(
                    size: 34,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                Color.dawnlyOrange
            )

            Text(
                "\(statistics.currentStreak)"
            )
            .font(
                .system(
                    size: 58,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()

            Text("day streak")
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )

            Text(streakMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            Color(
                .secondarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }

    // MARK: - Streak Metric

    private func streakMetric(
        title: String,
        value: String,
        subtitle: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                Color.dawnlyOrange
            )

            Text(title)
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)

            HStack(
                alignment: .firstTextBaseline,
                spacing: 4
            ) {

                Text(value)
                    .font(
                        .system(
                            size: 24,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()

                Text(subtitle)
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(16)
        .background(
            Color(
                .secondarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    // MARK: - Activity Calendar

    private var activityCalendarCard: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Focus activity")
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )

                    Text(
                        "Your last 12 weeks"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(
                    "\(activityDays.filter { $0.sessionCount > 0 }.count) days"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)
            }

            activityCalendar

            activityLegend
        }
        .padding(18)
        .background(
            Color(
                .secondarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    // MARK: - Calendar

    private var activityCalendar: some View {

        let weeks = calendarWeeks

        return HStack(
            alignment: .top,
            spacing: 4
        ) {

            // Weekday labels

            VStack(
                alignment: .trailing,
                spacing: 4
            ) {

                Spacer()
                    .frame(height: 16)

                Text("M")
                    .frame(height: 12)

                Text("W")
                    .frame(height: 12)

                Text("F")
                    .frame(height: 12)
            }
            .font(
                .system(
                    size: 8,
                    weight: .medium
                )
            )
            .foregroundStyle(.secondary)
            .frame(width: 12)

            // Weeks

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(
                    alignment: .top,
                    spacing: 4
                ) {

                    ForEach(
                        weeks.indices,
                        id: \.self
                    ) { weekIndex in

                        let week =
                            weeks[weekIndex]

                        VStack(spacing: 4) {

                            if let firstDay =
                                week.first {

                                Text(
                                    monthLabel(
                                        for: firstDay.date,
                                        weekIndex:
                                            weekIndex
                                    )
                                )
                                .font(
                                    .system(
                                        size: 8,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                                .frame(
                                    height: 16
                                )
                            }

                            ForEach(
                                week
                            ) { day in

                                activityCell(
                                    day
                                )
                            }
                        }
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Activity Cell

    private func activityCell(
        _ day: ActivityDay
    ) -> some View {

        RoundedRectangle(
            cornerRadius: 3,
            style: .continuous
        )
        .fill(
            activityColor(
                sessionCount:
                    day.sessionCount
            )
        )
        .frame(
            width: 12,
            height: 12
        )
        .overlay {

            if day.isToday {

                RoundedRectangle(
                    cornerRadius: 3,
                    style: .continuous
                )
                .stroke(
                    Color.dawnlyOrange,
                    lineWidth: 1.5
                )
            }
        }
        .help(
            activityDescription(
                for: day
            )
        )
    }

    // MARK: - Activity Color

    private func activityColor(
        sessionCount: Int
    ) -> Color {

        switch sessionCount {

        case 0:
            return Color.secondary.opacity(0.10)

        case 1:
            return Color.dawnlyOrange.opacity(0.30)

        case 2:
            return Color.dawnlyOrange.opacity(0.55)

        case 3:
            return Color.dawnlyOrange.opacity(0.75)

        default:
            return Color.dawnlyOrange
        }
    }

    // MARK: - Activity Description

    private func activityDescription(
        for day: ActivityDay
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.dateStyle = .medium

        let date =
            formatter.string(
                from: day.date
            )

        if day.sessionCount == 0 {

            return "\(date): No sessions"
        }

        let sessionText =
            day.sessionCount == 1
            ? "session"
            : "sessions"

        return "\(date): \(day.sessionCount) \(sessionText)"
    }

    // MARK: - Month Label

    private func monthLabel(
        for date: Date,
        weekIndex: Int
    ) -> String {

        let calendar =
            Calendar.current

        // Only display the month name when
        // the week begins in a new month.

        if weekIndex == 0 ||
            calendar.component(
                .month,
                from: date
            ) != calendar.component(
                .month,
                from:
                    calendarWeeks[
                        max(0, weekIndex - 1)
                    ].first?.date ?? date
            ) {

            let formatter =
                DateFormatter()

            formatter.dateFormat = "MMM"

            return formatter.string(
                from: date
            )
        }

        return ""
    }

    // MARK: - Activity Data

    private var activityDays: [ActivityDay] {

        let calendar =
            Calendar.current

        let today =
            calendar.startOfDay(
                for: Date()
            )

        guard let startDate =
            calendar.date(
                byAdding: .day,
                value: -83,
                to: today
            )
        else {
            return []
        }

        let sessionCounts =
            Dictionary(
                grouping:
                    completedSessions,
                by: {
                    calendar.startOfDay(
                        for: $0.startDate
                    )
                }
            )
            .mapValues {
                $0.count
            }

        var days: [ActivityDay] = []

        var currentDate =
            startDate

        while currentDate <= today {

            let count =
                sessionCounts[currentDate] ?? 0

            days.append(
                ActivityDay(
                    date: currentDate,
                    sessionCount: count,
                    isToday:
                        calendar.isDate(
                            currentDate,
                            inSameDayAs: today
                        )
                )
            )

            guard let nextDate =
                calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: currentDate
                )
            else {
                break
            }

            currentDate = nextDate
        }

        return days
    }

    // MARK: - Calendar Weeks

    private var calendarWeeks: [[ActivityDay]] {

        let calendar =
            Calendar.current

        guard let firstDay =
            activityDays.first
        else {
            return []
        }

        guard let lastDay =
            activityDays.last
        else {
            return []
        }

        let firstWeekday =
            calendar.component(
                .weekday,
                from: firstDay.date
            )

        // Convert Sunday = 1 ... Saturday = 7
        // into Monday = 0 ... Sunday = 6.

        let mondayOffset =
            (firstWeekday + 5) % 7

        var paddedDays =
            Array(
                repeating:
                    Optional<ActivityDay>.none,
                count: mondayOffset
            )

        paddedDays.append(
            contentsOf:
                activityDays.map {
                    Optional($0)
                }
        )

        let remainder =
            paddedDays.count % 7

        if remainder != 0 {

            paddedDays.append(
                contentsOf:
                    Array(
                        repeating:
                            Optional<ActivityDay>.none,
                        count:
                            7 - remainder
                    )
            )
        }

        var weeks:
            [[ActivityDay]] = []

        var index = 0

        while index < paddedDays.count {

            let chunk =
                paddedDays[
                    index..<min(
                        index + 7,
                        paddedDays.count
                    )
                ]

            let validDays =
                chunk.compactMap {
                    $0
                }

            if !validDays.isEmpty {
                weeks.append(validDays)
            }

            index += 7
        }

        // Make sure the most recent week is retained
        // even if the date range doesn't start on Monday.

        _ = lastDay

        return weeks
    }

    // MARK: - Legend

    private var activityLegend: some View {

        HStack(spacing: 5) {

            Text("Less")
                .font(
                    .system(
                        size: 9,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)

            ForEach(
                0..<5,
                id: \.self
            ) { level in

                RoundedRectangle(
                    cornerRadius: 3,
                    style: .continuous
                )
                .fill(
                    activityColor(
                        sessionCount: level
                    )
                )
                .frame(
                    width: 12,
                    height: 12
                )
            }

            Text("More")
                .font(
                    .system(
                        size: 9,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {

        HStack(spacing: 14) {

            Image(
                systemName:
                    statistics.focusedToday
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(
                .system(
                    size: 24,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                statistics.focusedToday
                    ? Color.dawnlyOrange
                    : Color.secondary
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    statistics.focusedToday
                        ? "Today's streak is active"
                        : "Focus today to keep your streak going"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )

                Text(
                    statistics.sessionsToday == 0
                        ? "No completed sessions today."
                        : "\(statistics.sessionsToday) completed session\(statistics.sessionsToday == 1 ? "" : "s") today."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            Color(
                .secondarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    // MARK: - Streak Message

    private var streakMessage: String {

        switch statistics.currentStreak {

        case 0:
            return "Complete a focus session today to start your streak."

        case 1:
            return "Great start. Come back tomorrow to make it 2 days."

        case 2...6:
            return "Keep going. You're building a habit."

        case 7...13:
            return "One week strong. Keep the momentum going."

        case 14...29:
            return "Amazing consistency. You're building a real routine."

        default:
            return "Incredible consistency. Keep your focus going."
        }
    }
}

// MARK: - Activity Day

private struct ActivityDay: Identifiable {

    let date: Date
    let sessionCount: Int
    let isToday: Bool

    var id: Date {
        date
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        StreakView()
    }
    .modelContainer(
        for: FocusSession.self
    )
}
