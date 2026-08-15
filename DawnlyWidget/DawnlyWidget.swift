import ActivityKit
import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct DawnlyWidgetEntry: TimelineEntry {

    let date: Date

    // Today's completed focus time
    let focusTime: TimeInterval

    // Active timer information
    let isSessionRunning: Bool
    let sessionStartDate: Date?
    let sessionEndDate: Date?
}

// MARK: - Provider

struct DawnlyWidgetProvider: TimelineProvider {

    // MARK: Placeholder

    func placeholder(
        in context: Context
    ) -> DawnlyWidgetEntry {

        DawnlyWidgetEntry(
            date: Date(),
            focusTime: 25 * 60,
            isSessionRunning: true,
            sessionStartDate: Date(),
            sessionEndDate: Date().addingTimeInterval(25 * 60)
        )
    }

    // MARK: Snapshot

    func getSnapshot(
        in context: Context,
        completion: @escaping (DawnlyWidgetEntry) -> Void
    ) {

        let runningSession =
            DawnlySharedState.runningSession()

        let entry = DawnlyWidgetEntry(
            date: Date(),
            focusTime: todaysFocusTime(),
            isSessionRunning: runningSession != nil,
            sessionStartDate: runningSession?.startDate,
            sessionEndDate: runningSession?.endDate
        )

        completion(entry)
    }

    // MARK: Timeline

    func getTimeline(
        in context: Context,
        completion: @escaping (
            Timeline<DawnlyWidgetEntry>
        ) -> Void
    ) {

        let now = Date()

        let runningSession =
            DawnlySharedState.runningSession()

        let isRunning: Bool

        if let runningSession {

            isRunning =
                runningSession.endDate > now

        } else {

            isRunning = false
        }

        let entry = DawnlyWidgetEntry(
            date: now,
            focusTime: todaysFocusTime(),
            isSessionRunning: isRunning,
            sessionStartDate: runningSession?.startDate,
            sessionEndDate: runningSession?.endDate
        )

        // If a session is running, ask WidgetKit
        // to refresh shortly after it finishes.
        //
        // The actual countdown itself is rendered
        // by Text(timerInterval:countingDown:).

        let nextRefresh: Date

        if let endDate = runningSession?.endDate,
           endDate > now {

            nextRefresh = endDate

        } else {

            nextRefresh =
                Calendar.current.date(
                    byAdding: .minute,
                    value: 15,
                    to: now
                )
                ?? now.addingTimeInterval(15 * 60)
        }

        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextRefresh)
        )

        completion(timeline)
    }

    // MARK: SwiftData

    private func todaysFocusTime() -> TimeInterval {

        let container =
            SharedModelContainer.container

        let context =
            ModelContext(container)

        let calendar =
            Calendar.current

        let startOfDay =
            calendar.startOfDay(
                for: Date()
            )

        let descriptor =
            FetchDescriptor<FocusSession>(
                predicate: #Predicate { session in

                    session.completed &&
                    session.startDate >= startOfDay
                }
            )

        do {

            let sessions =
                try context.fetch(
                    descriptor
                )

            return sessions.reduce(0) {
                $0 + $1.duration
            }

        } catch {

            print(
                "Dawnly Widget fetch error: \(error)"
            )

            return 0
        }
    }
}

// MARK: - Widget View

struct DawnlyWidgetEntryView: View {

    let entry:
        DawnlyWidgetProvider.Entry

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            // MARK: Header

            HStack(spacing: 6) {

                Image(
                    systemName:
                        entry.isSessionRunning
                        ? "timer"
                        : "sun.max.fill"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.accentColor
                )

                Text("Dawnly")
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )

                Spacer()

                if entry.isSessionRunning {

                    Circle()
                        .fill(
                            Color.accentColor
                        )
                        .frame(
                            width: 6,
                            height: 6
                        )
                }
            }

            Spacer()

            // MARK: Main Content

            if entry.isSessionRunning,
               let startDate =
                    entry.sessionStartDate,
               let endDate =
                    entry.sessionEndDate {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text("Focus session")
                        .font(
                            .system(
                                size: 12
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        timerInterval:
                            startDate
                            ...
                            endDate,
                        countsDown: true
                    )
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                }

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text("Today's focus")
                        .font(
                            .system(
                                size: 12
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        formatFocusTime(
                            entry.focusTime
                        )
                    )
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                }
            }

            Spacer()

            // MARK: Footer

            HStack {

                Text(
                    entry.isSessionRunning
                    ? "Stay focused"
                    : (
                        entry.focusTime > 0
                        ? "Keep going"
                        : "Ready to focus"
                    )
                )
                .font(
                    .system(
                        size: 11
                    )
                )
                .foregroundStyle(
                    .secondary
                )

                Spacer()

                Image(
                    systemName:
                        "arrow.up.right"
                )
                .font(
                    .system(
                        size: 9,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(16)
        .containerBackground(
            for: .widget
        ) {

            Color.accentColor
                .opacity(0.06)
        }
    }

    // MARK: Formatting

    private func formatFocusTime(
        _ time: TimeInterval
    ) -> String {

        let totalMinutes =
            Int(time / 60)

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

// MARK: - Home Screen Widget

struct DawnlyWidget: Widget {

    let kind = "DawnlyWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider: DawnlyWidgetProvider()
        ) { entry in

            DawnlyWidgetEntryView(
                entry: entry
            )
        }
        .configurationDisplayName(
            "Dawnly"
        )
        .description(
            "See your focus time and active session."
        )
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

// MARK: - Live Activity

struct DawnlyLiveActivity: Widget {

    var body: some WidgetConfiguration {

        ActivityConfiguration(
            for: DawnlyActivityAttributes.self
        ) { context in

            // MARK: Lock Screen

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                HStack {

                    HStack(spacing: 8) {

                        Image(
                            systemName:
                                "sun.max.fill"
                        )
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            Color.accentColor
                        )

                        Text("Dawnly")
                            .font(
                                .system(
                                    size: 15,
                                    weight: .semibold
                                )
                            )
                    }

                    Spacer()

                    Text("FOCUSING")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .tracking(1.2)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer(minLength: 16)

                Text(
                    timerInterval:
                        context.state.startDate
                        ...
                        context.state.endDate,
                    countsDown: true
                )
                .font(
                    .system(
                        size: 44,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Spacer(minLength: 6)

                Text("Stay focused.")
                    .font(
                        .system(
                            size: 13
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )

                Spacer(minLength: 16)

                Capsule()
                    .fill(
                        Color.accentColor
                            .opacity(0.15)
                    )
                    .frame(height: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .activityBackgroundTint(
                Color(.systemBackground)
            )
            .activitySystemActionForegroundColor(
                Color.accentColor
            )

        } dynamicIsland: { context in

            DynamicIsland {

                // MARK: Expanded Leading

                DynamicIslandExpandedRegion(
                    .leading
                ) {

                    HStack(spacing: 6) {

                        Image(
                            systemName:
                                "sun.max.fill"
                        )
                        .foregroundStyle(
                            Color.accentColor
                        )

                        Text("Dawnly")
                            .font(
                                .caption.bold()
                            )
                    }
                }

                // MARK: Expanded Trailing

                DynamicIslandExpandedRegion(
                    .trailing
                ) {

                    Text("FOCUS")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .tracking(1)
                        .foregroundStyle(
                            .secondary
                        )
                }

                // MARK: Expanded Center

                DynamicIslandExpandedRegion(
                    .center
                ) {

                    Text(
                        timerInterval:
                            context.state.startDate
                            ...
                            context.state.endDate,
                        countsDown: true
                    )
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                }

                // MARK: Expanded Bottom

                DynamicIslandExpandedRegion(
                    .bottom
                ) {

                    HStack {

                        Text("Stay focused.")
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )

                        Spacer()

                        Circle()
                            .fill(
                                Color.accentColor
                            )
                            .frame(
                                width: 6,
                                height: 6
                            )
                    }
                }

            } compactLeading: {

                Image(
                    systemName:
                        "sun.max.fill"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.accentColor
                )

            } compactTrailing: {

                Text(
                    timerInterval:
                        context.state.startDate
                        ...
                        context.state.endDate,
                    countsDown: true
                )
                .font(
                    .system(
                        size: 13,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .monospacedDigit()

            } minimal: {

                Image(
                    systemName:
                        "timer"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.accentColor
                )
            }
        }
    }
}
