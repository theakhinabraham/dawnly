import SwiftUI
import SwiftData

struct StatisticsView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var selectedPeriod: StatisticsPeriod = .week

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header

                VStack(alignment: .leading, spacing: 6) {

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

                // MARK: - Period Picker

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

                // MARK: - Main Statistics

                StatisticsSummaryCard(
                    period: selectedPeriod
                )

                // MARK: - Daily Breakdown

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
            .padding()
        }
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

// MARK: - Statistics Summary

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

            Text("Focus time")
                .font(.headline)

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        manager.formattedDuration(
                            totalFocus
                        )
                    )
                    .font(
                        .system(
                            size: 36,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()

                    Text(
                        "\(sessionCount) completed " +
                        (sessionCount == 1
                         ? "session"
                         : "sessions")
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: "timer"
                )
                .font(
                    .system(
                        size: 28,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.accentColor
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.accentColor.opacity(0.08),
            in: RoundedRectangle(
                cornerRadius: 20
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

    private var dailyData: [(date: Date, duration: TimeInterval)] {

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

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("Daily focus")
                .font(.headline)

            if dailyData.isEmpty {

                VStack(spacing: 10) {

                    Image(
                        systemName: "chart.bar.xaxis"
                    )
                    .font(.title2)
                    .foregroundStyle(.secondary)

                    Text("No focus sessions yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 120
                )

            } else {

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
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    private var maximumDuration: TimeInterval {

        dailyData
            .map(\.duration)
            .max() ?? 1
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

        return duration / maximum
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            HStack {

                Text(
                    date.formatted(
                        .dateTime
                            .weekday(.abbreviated)
                            .day()
                    )
                )
                .font(.subheadline)

                Spacer()

                Text(
                    formattedDuration
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
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
                                Color.accentColor
                            )
                            .frame(
                                width:
                                    geometry.size.width *
                                    progress
                            )
                    }
            }
            .frame(height: 6)
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

            Text("Session insights")
                .font(.headline)

            HStack(spacing: 12) {

                InsightItem(
                    title: "Average",
                    value: manager.formattedDuration(
                        manager.averageSessionDuration(
                            sessions: sessions
                        )
                    ),
                    icon: "chart.bar"
                )

                InsightItem(
                    title: "Longest",
                    value: manager.formattedDuration(
                        manager.longestSession(
                            sessions: sessions
                        )
                    ),
                    icon: "flame"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 20
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
            spacing: 10
        ) {

            Image(
                systemName: icon
            )
            .foregroundStyle(
                Color.accentColor
            )

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .system(
                        size: 20,
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
                cornerRadius: 14
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
                Color.accentColor
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Current streak")
                    .font(.headline)

                Text(
                    streak == 1
                    ? "1 day"
                    : "\(streak) days"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .rounded
                    )
                )
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.accentColor.opacity(0.08),
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}
