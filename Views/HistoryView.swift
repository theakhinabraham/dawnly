import SwiftUI
import SwiftData

// MARK: - History View

struct HistoryView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<FocusSession> { session in
            session.completed
        },
        sort: \FocusSession.startDate,
        order: .reverse
    )
    private var sessions: [FocusSession]

    // MARK: - Delete

    private func deleteSession(
        _ session: FocusSession
    ) {

        modelContext.delete(session)

        do {

            try modelContext.save()

        } catch {

            print(
                "Dawnly: Failed to delete session: \(error)"
            )
        }
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 28
                ) {

                    // MARK: - Today's Summary

                    TodayHistoryCard(
                        focusTime: todayFocusTime,
                        sessionCount: todaySessionCount
                    )

                    // MARK: - History

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

                        HStack {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text("History")
                                    .font(
                                        .system(
                                            size: 24,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )

                                if !sessions.isEmpty {

                                    Text(
                                        sessions.count == 1
                                        ? "1 completed session"
                                        : "\(sessions.count) completed sessions"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if !sessions.isEmpty {

                                Image(
                                    systemName: "clock.arrow.circlepath"
                                )
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    Color.dawnlyOrange
                                )
                            }
                        }

                        if sessions.isEmpty {

                            EmptyHistoryView()

                        } else {

                            VStack(
                                alignment: .leading,
                                spacing: 24
                            ) {

                                ForEach(
                                    groupedSessions,
                                    id: \.date
                                ) { group in

                                    HistoryDaySection(
                                        group: group,
                                        onDelete: deleteSession
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(
                Color(.systemGroupedBackground)
            )
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Today's Sessions

    private var todaySessions: [FocusSession] {

        let calendar = Calendar.current

        return sessions.filter {

            calendar.isDateInToday(
                $0.startDate
            )
        }
    }

    // MARK: - Today's Focus Time

    private var todayFocusTime: TimeInterval {

        todaySessions.reduce(0) {

            $0 + $1.duration
        }
    }

    // MARK: - Today's Session Count

    private var todaySessionCount: Int {

        todaySessions.count
    }

    // MARK: - Group Sessions

    private var groupedSessions: [SessionGroup] {

        let calendar = Calendar.current

        let groups = Dictionary(
            grouping: sessions
        ) { session in

            calendar.startOfDay(
                for: session.startDate
            )
        }

        return groups
            .sorted {
                $0.key > $1.key
            }
            .map { date, sessions in

                SessionGroup(
                    date: date,
                    title: sectionTitle(
                        for: date
                    ),
                    sessions: sessions
                )
            }
    }

    // MARK: - Section Title

    private func sectionTitle(
        for date: Date
    ) -> String {

        let calendar = Calendar.current

        if calendar.isDateInToday(date) {

            return "Today"
        }

        if calendar.isDateInYesterday(date) {

            return "Yesterday"
        }

        return date.formatted(
            .dateTime
                .weekday(.wide)
                .month(.wide)
                .day()
        )
    }
}

// MARK: - Today's History Card

private struct TodayHistoryCard: View {

    let focusTime: TimeInterval
    let sessionCount: Int

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Today's Focus")
                        .font(.headline)

                    Text("Your progress today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: "sun.max.fill"
                )
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    Color.dawnlyOrange.opacity(0.12),
                    in: Circle()
                )
            }

            Text(
                formattedFocusTime
            )
            .font(
                .system(
                    size: 42,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()

            HStack(spacing: 8) {

                Image(
                    systemName: "checkmark.circle.fill"
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )

                Text(
                    sessionCount == 1
                    ? "1 completed session"
                    : "\(sessionCount) completed sessions"
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

    private var formattedFocusTime: String {

        let totalMinutes =
            Int(focusTime / 60)

        let hours =
            totalMinutes / 60

        let minutes =
            totalMinutes % 60

        if hours > 0 {

            if minutes == 0 {

                return "\(hours)h"
            }

            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}

// MARK: - History Day Section

private struct HistoryDaySection: View {

    let group: SessionGroup

    let onDelete:
        (FocusSession) -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            // Day Header

            HStack {

                Text(group.title)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )

                Spacer()

                Text(
                    sessionCountText
                )
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)

            // Sessions

            VStack(spacing: 8) {

                ForEach(
                    group.sessions
                ) { session in

                    SessionRow(
                        session: session
                    )
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: true
                    ) {

                        Button(
                            role: .destructive
                        ) {

                            onDelete(session)

                        } label: {

                            Label(
                                "Delete",
                                systemImage: "trash"
                            )
                        }
                    }
                }
            }
        }
    }

    private var sessionCountText: String {

        group.sessions.count == 1
        ? "1 session"
        : "\(group.sessions.count) sessions"
    }
}

// MARK: - Session Group

private struct SessionGroup {

    let date: Date
    let title: String
    let sessions: [FocusSession]
}

// MARK: - Session Row

private struct SessionRow: View {

    let session: FocusSession

    var body: some View {

        HStack(spacing: 14) {

            // Completion Icon

            Image(
                systemName:
                    "checkmark.circle.fill"
            )
            .font(
                .system(
                    size: 22,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                Color.dawnlyOrange
            )

            // Session Details

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(durationText)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )

                Text(
                    session.startDate,
                    format:
                        .dateTime
                        .hour()
                        .minute()
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Session End Time

            VStack(
                alignment: .trailing,
                spacing: 3
            ) {

                Text("Completed")
                    .font(
                        .system(
                            size: 10,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)

                Text(
                    endTimeText
                )
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)
            }
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

    // MARK: - Duration

    private var durationText: String {

        let totalMinutes =
            Int(session.duration / 60)

        if totalMinutes < 60 {

            if totalMinutes == 1 {

                return "1 minute"
            }

            return "\(totalMinutes) minutes"
        }

        let hours =
            totalMinutes / 60

        let minutes =
            totalMinutes % 60

        if minutes == 0 {

            return hours == 1
                ? "1 hour"
                : "\(hours) hours"
        }

        return "\(hours)h \(minutes)m"
    }

    // MARK: - End Time

    private var endTimeText: String {

        session.endDate.formatted(
            .dateTime
                .hour()
                .minute()
        )
    }
}

// MARK: - Empty History

private struct EmptyHistoryView: View {

    var body: some View {

        VStack(spacing: 14) {

            Image(
                systemName: "clock"
            )
            .font(
                .system(
                    size: 28,
                    weight: .medium
                )
            )
            .foregroundStyle(
                Color.dawnlyOrange
            )
            .frame(
                width: 58,
                height: 58
            )
            .background(
                Color.dawnlyOrange.opacity(0.10),
                in: Circle()
            )

            Text("No Sessions Yet")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )

            Text(
                "Complete your first focus session and your history will appear here."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 220
        )
        .padding(24)
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
}

// MARK: - Preview

#Preview {

    HistoryView()
        .modelContainer(
            for: FocusSession.self
        )
}
