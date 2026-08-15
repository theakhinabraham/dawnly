import SwiftUI
import SwiftData

// MARK: - Dawnly Theme

private extension Color {

    static let dawnlyOrange = Color(
        red: 1.0,
        green: 0.55,
        blue: 0.15
    )
}

// MARK: - Statistics View

struct StatisticsView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var selectedPeriod: StatisticsPeriod = .week

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                // MARK: - Header

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text("Statistics")
                        .font(
                            .system(
                                size: 32,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text("Your focus journey at a glance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Period Selector

                Picker(
                    "Period",
                    selection: $selectedPeriod
                ) {

                    ForEach(
                        StatisticsPeriod.allCases,
                        id: \.self
                    ) { period in

                        Text(period.title)
                            .tag(period)
                    }
                }
                .pickerStyle(.segmented)

                // MARK: - Focus Summary

                StatisticsSummaryCard(
                    period: selectedPeriod
                )

                // MARK: - Daily Focus

                DailyFocusCard(
                    period: selectedPeriod
                )

                // MARK: - Session Insights

                SessionInsightsCard(
                    period: selectedPeriod
                )

                // MARK: - Streak

                StreakCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Statistics Period

enum StatisticsPeriod: CaseIterable {

    case today
    case week
    case month

    var title: String {

        switch self {

        case .today:
            return "Today"

        case .week:
            return "Week"

        case .month:
            return "Month"
        }
    }
}

// MARK: - Statistics Summary Card

struct StatisticsSummaryCard: View {

    @Environment(\.modelContext) private var modelContext

    let period: StatisticsPeriod

    private var manager: StatisticsManager {

        StatisticsManager(
            context: modelContext
        )
    }

    private var sessions: [FocusSession] {

        switch period {

        case .today:
            return manager.todaysSessions()

        case .week:
            return manager.thisWeeksSessions()

        case .month:
            return manager.thisMonthsSessions()
        }
    }

    private var totalFocus: TimeInterval {

        manager.totalFocusTime(
            sessions: sessions
        )
    }

    private var sessionCount: Int {

        manager.sessionCount(
            sessions: sessions
        )
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            // Header

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Focus time")
                        .font(.headline)

                    Text(period.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "timer")
                    .font(
                        .system(
                            size: 22,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        Color.dawnlyOrange
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )
                    .background(
                        Color.dawnlyOrange.opacity(0.12),
                        in: Circle()
                    )
            }

            // Main value

            Text(
                manager.formattedDuration(
                    totalFocus
                )
            )
            .font(
                .system(
                    size: 42,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()

            // Session information

            HStack(spacing: 8) {

                Image(
                    systemName: "checkmark.circle.fill"
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )

                Text(
                    "\(sessionCount) completed " +
                    (
                        sessionCount == 1
                        ? "session"
                        : "sessions"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.dawnlyOrange.opacity(0.16),
                    Color.dawnlyOrange.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Daily Focus Card

struct DailyFocusCard: View {

    @Environment(\.modelContext) private var modelContext

    let period: StatisticsPeriod

    private var manager: StatisticsManager {

        StatisticsManager(
            context: modelContext
        )
    }

    private var sessions: [FocusSession] {

        switch period {

        case .today:
            return manager.todaysSessions()

        case .week:
            return manager.thisWeeksSessions()

        case .month:
            return manager.thisMonthsSessions()
        }
    }

    private var dailyData:
        [(date: Date, duration: TimeInterval)] {

        manager.dailyFocusTime(
            sessions: sessions
        )
        .map {
            (
                date: $0.key,
                duration: $0.value
            )
        }
        .sorted {
            $0.date < $1.date
        }
    }

    private var maximumDuration: TimeInterval {

        dailyData
            .map(\.duration)
            .max() ?? 1
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            // Header

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Daily focus")
                        .font(.headline)

                    Text(
                        period == .today
                        ? "Your focus today"
                        : "Focus by day"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: "chart.bar.fill"
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )
            }

            if dailyData.isEmpty {

                EmptyStatisticsView(
                    icon: "chart.bar.xaxis",
                    title: "No focus yet",
                    message: "Complete a focus session to see your daily progress."
                )

            } else {

                VStack(spacing: 16) {

                    ForEach(
                        dailyData,
                        id: \.date
                    ) { item in

                        DailyFocusRow(
                            date: item.date,
                            duration: item.duration,
                            maximum: maximumDuration
                        )
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Daily Focus Row

struct DailyFocusRow: View {

    let date: Date
    let duration: TimeInterval
    let maximum: TimeInterval

    private var progress: Double {

        guard maximum > 0 else {
            return 0
        }

        return min(
            max(duration / maximum, 0),
            1
        )
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(
                    date.formatted(
                        .dateTime
                            .weekday(.abbreviated)
                            .day()
                    )
                )
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )

                Spacer()

                Text(formattedDuration)
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in

                Capsule()
                    .fill(
                        Color.secondary.opacity(0.12)
                    )
                    .overlay(alignment: .leading) {

                        Capsule()
                            .fill(
                                Color.dawnlyOrange
                            )
                            .frame(
                                width:
                                    geometry.size.width *
                                    progress
                            )
                    }
            }
            .frame(height: 7)
        }
    }

    private var formattedDuration: String {

        let minutes = Int(duration / 60)

        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remainingMinutes)m"
    }
}

// MARK: - Session Insights

struct SessionInsightsCard: View {

    @Environment(\.modelContext) private var modelContext

    let period: StatisticsPeriod

    private var manager: StatisticsManager {

        StatisticsManager(
            context: modelContext
        )
    }

    private var sessions: [FocusSession] {

        switch period {

        case .today:
            return manager.todaysSessions()

        case .week:
            return manager.thisWeeksSessions()

        case .month:
            return manager.thisMonthsSessions()
        }
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Session insights")
                        .font(.headline)

                    Text("Understand your focus habits.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: "sparkles"
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )
            }

            HStack(spacing: 12) {

                InsightItem(
                    title: "Average",
                    value: manager.formattedDuration(
                        manager.averageSessionDuration(
                            sessions: sessions
                        )
                    ),
                    icon: "chart.bar.fill"
                )

                InsightItem(
                    title: "Longest",
                    value: manager.formattedDuration(
                        manager.longestSession(
                            sessions: sessions
                        )
                    ),
                    icon: "flame.fill"
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Insight Item

struct InsightItem: View {

    let title: String
    let value: String
    let icon: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Image(systemName: icon)
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Color.dawnlyOrange.opacity(0.12),
                    in: Circle()
                )

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(16)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
}

// MARK: - Streak Card

struct StreakCard: View {

    @Environment(\.modelContext) private var modelContext

    private var streak: Int {

        StatisticsManager(
            context: modelContext
        )
        .currentFocusStreak()
    }

    var body: some View {

        HStack(spacing: 16) {

            Image(
                systemName: "flame.fill"
            )
            .font(
                .system(
                    size: 24,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                Color.dawnlyOrange
            )
            .frame(
                width: 52,
                height: 52
            )
            .background(
                Color.dawnlyOrange.opacity(0.12),
                in: Circle()
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Current streak")
                    .font(.headline)

                if streak == 0 {

                    Text("Start your streak today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                } else {

                    Text(
                        streak == 1
                        ? "1 day"
                        : "\(streak) days"
                    )
                    .font(
                        .system(
                            size: 25,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                }
            }

            Spacer()

            if streak > 0 {

                VStack(
                    alignment: .trailing,
                    spacing: 3
                ) {

                    Text("KEEP GOING")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .tracking(0.8)
                        .foregroundStyle(
                            Color.dawnlyOrange
                        )

                    Image(
                        systemName: "arrow.up.right"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.dawnlyOrange.opacity(0.14),
                    Color.dawnlyOrange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Empty Statistics View

private struct EmptyStatisticsView: View {

    let icon: String
    let title: String
    let message: String

    var body: some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 110
        )
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        StatisticsView()
    }
}
