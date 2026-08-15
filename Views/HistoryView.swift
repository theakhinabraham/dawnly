import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(
        filter: #Predicate<FocusSession> { session in
            session.completed
        },
        sort: \FocusSession.startDate,
        order: .reverse
    )
    private var sessions: [FocusSession]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 32) {

                    // MARK: - Today's Focus

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Today's Focus")
                            .font(.headline)

                        Text(todayFocusText)
                            .font(
                                .system(
                                    size: 42,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .monospacedDigit()

                        Text("\(todaySessionCount) completed sessions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: - History

                    VStack(alignment: .leading, spacing: 20) {

                        Text("History")
                            .font(.title2.bold())

                        if sessions.isEmpty {

                            ContentUnavailableView(
                                "No Sessions Yet",
                                systemImage: "clock",
                                description: Text(
                                    "Complete a focus session and it will appear here."
                                )
                            )

                        } else {

                            ForEach(groupedSessions, id: \.date) { group in

                                VStack(
                                    alignment: .leading,
                                    spacing: 12
                                ) {

                                    Text(group.title)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)

                                    ForEach(group.sessions) { session in

                                        SessionRow(
                                            session: session
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Today's Focus

    private var todaySessions: [FocusSession] {

        let calendar = Calendar.current

        return sessions.filter {
            calendar.isDateInToday($0.startDate)
        }
    }

    private var todayFocusTime: TimeInterval {

        todaySessions.reduce(0) {
            $0 + $1.duration
        }
    }

    private var todayFocusText: String {

        let totalMinutes = Int(todayFocusTime / 60)

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

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
            .sorted { $0.key > $1.key }
            .map { date, sessions in

                SessionGroup(
                    date: date,
                    title: sectionTitle(for: date),
                    sessions: sessions
                )
            }
    }

    private func sectionTitle(for date: Date) -> String {

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

        HStack(spacing: 16) {

            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(durationText)
                    .font(.headline)

                Text(
                    session.startDate,
                    style: .time
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                session.startDate,
                format: .dateTime.hour().minute()
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            Color.gray.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var durationText: String {

        let minutes = Int(session.duration / 60)

        if minutes == 1 {
            return "1 minute"
        }

        return "\(minutes) minutes"
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: FocusSession.self)
}
