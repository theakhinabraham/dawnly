import ActivityKit
import WidgetKit
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

// MARK: - Timeline Entry

struct DawnlyWidgetEntry: TimelineEntry {

    let date: Date

    let focusTime: TimeInterval

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

        let startDate = Date()

        return DawnlyWidgetEntry(
            date: startDate,
            focusTime: 25 * 60,
            isSessionRunning: true,
            sessionStartDate: startDate,
            sessionEndDate: startDate.addingTimeInterval(
                25 * 60
            )
        )
    }

    // MARK: Snapshot

    func getSnapshot(
        in context: Context,
        completion: @escaping (DawnlyWidgetEntry) -> Void
    ) {

        let runningSession =
            DawnlySharedState.runningSession()

        let now = Date()

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

        // Refresh when the session finishes.

        let nextRefresh: Date

        if let endDate =
            runningSession?.endDate,
            endDate > now {

            nextRefresh = endDate

        } else {

            nextRefresh =
                Calendar.current.date(
                    byAdding: .minute,
                    value: 15,
                    to: now
                )
                ?? now.addingTimeInterval(
                    15 * 60
                )
        }

        let timeline =
            Timeline(
                entries: [entry],
                policy: .after(nextRefresh)
            )

        completion(timeline)
    }

    // MARK: SwiftData

    private func todaysFocusTime()
        -> TimeInterval {

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
                predicate: #Predicate {
                    session in

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

            HStack {

                Image(
                    systemName:
                        entry.isSessionRunning
                        ? "timer"
                        : "sun.max.fill"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )

                Spacer()

                if entry.isSessionRunning {

                    Circle()
                        .fill(
                            Color.dawnlyOrange
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
                            startDate...endDate,
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
                    .foregroundStyle(
                        Color.dawnlyOrange
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
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
                    .foregroundStyle(
                        Color.dawnlyOrange
                    )
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

            Color.dawnlyOrange
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

import ActivityKit
import WidgetKit
import SwiftUI

struct DawnlyLiveActivity: Widget {

    var body: some WidgetConfiguration {

        ActivityConfiguration<
            DawnlyActivityAttributes
        >(
            for: DawnlyActivityAttributes.self
        ) { context in

            // =========================================================
            // MARK: Lock Screen / Banner
            // =========================================================

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                // MARK: Header

                HStack {

                    HStack(spacing: 9) {

                        Image(
                            systemName: "sun.max.fill"
                        )
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(Color.orange)

                        Text("Dawnly")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                    }

                    Spacer()

                    Text(
                        timerText(context.state)
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )
                }

                // MARK: Progress

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    ProgressView(
                        timerInterval:
                            context.state.startDate
                            ...
                            context.state.endDate,
                        countsDown: false
                    )
                    .progressViewStyle(.linear)
                    .tint(Color.orange)

                    HStack {

                        Text("Focus session")
                            .font(
                                .system(
                                    size: 11,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(
                            "\(Int(context.attributes.sessionDuration / 60)) min"
                        )
                        .font(
                            .system(
                                size: 11,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .activityBackgroundTint(
                Color(.systemBackground)
            )
            .activitySystemActionForegroundColor(
                Color.orange
            )

        } dynamicIsland: { context in

            // =========================================================
            // MARK: Dynamic Island
            // =========================================================

            DynamicIsland {

                // MARK: Expanded Leading

                DynamicIslandExpandedRegion(
                    .leading
                ) {

                    HStack(spacing: 7) {

                        Image(
                            systemName: "sun.max.fill"
                        )
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(Color.orange)

                        Text("Dawnly")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .lineLimit(1)
                            .fixedSize(
                                horizontal: true,
                                vertical: false
                            )
                            .allowsTightening(true)
                    }
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )
                }

                // MARK: Expanded Trailing

                DynamicIslandExpandedRegion(
                    .trailing
                ) {

                    Text(
                        timerText(context.state)
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .frame(
                        width: 58,
                        alignment: .trailing
                    )
                }

                // MARK: Expanded Center

                DynamicIslandExpandedRegion(
                    .center
                ) {

                    VStack(
                        spacing: 12
                    ) {

                        Text("Focus session")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.secondary)

                        ProgressView(
                            timerInterval:
                                context.state.startDate
                                ...
                                context.state.endDate,
                            countsDown: false
                        )
                        .progressViewStyle(.linear)
                        .tint(Color.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }

                // MARK: Expanded Bottom

                DynamicIslandExpandedRegion(
                    .bottom
                ) {

                    HStack {

                        HStack(spacing: 6) {

                            Circle()
                                .fill(Color.orange)
                                .frame(
                                    width: 5,
                                    height: 5
                                )

                            Text("Focusing")
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(
                            "\(Int(context.attributes.sessionDuration / 60)) min session"
                        )
                        .font(
                            .system(
                                size: 11,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                }

            } compactLeading: {

                Image(
                    systemName: "sun.max.fill"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Color.orange)

            } compactTrailing: {

                Text(
                    timerText(context.state)
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(
                    horizontal: true,
                    vertical: false
                )

            } minimal: {

                Image(
                    systemName: "sun.max.fill"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Color.orange)
            }
        }
    }

    // =============================================================
    // MARK: Timer Text
    // =============================================================

    private func timerText(
        _ state:
            DawnlyActivityAttributes.ContentState
    ) -> String {

        let remaining =
            max(
                state.endDate.timeIntervalSinceNow,
                0
            )

        let totalSeconds =
            Int(remaining)

        let minutes =
            totalSeconds / 60

        let seconds =
            totalSeconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}

// MARK: - Live Activity Progress Style

private struct DawnlyLiveActivityProgressStyle:
    ProgressViewStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        GeometryReader { geometry in

            ZStack(alignment: .leading) {

                // Background

                Capsule()
                    .fill(
                        Color.dawnlyOrange
                            .opacity(0.16)
                    )

                // Active progress

                Capsule()
                    .fill(
                        Color.dawnlyOrange
                    )
                    .frame(
                        width: progressWidth(
                            geometryWidth:
                                geometry.size.width,
                            fraction:
                                configuration.fractionCompleted
                        )
                    )
            }
        }
        .frame(height: 5)
        .clipShape(
            Capsule()
        )
    }

    private func progressWidth(
        geometryWidth: CGFloat,
        fraction: Double?
    ) -> CGFloat {

        guard let fraction else {
            return 0
        }

        let clampedFraction =
            max(
                0,
                min(
                    fraction,
                    1
                )
            )

        return geometryWidth
            * CGFloat(clampedFraction)
    }
}

