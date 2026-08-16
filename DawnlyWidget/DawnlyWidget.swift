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

// MARK: - Live Activity

struct DawnlyLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        
        ActivityConfiguration(
            for: DawnlyActivityAttributes.self
        ) { context in
            
            // MARK: - Lock Screen Live Activity
            
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                
                // MARK: Header
                
                HStack(
                    alignment: .center,
                    spacing: 0
                ) {
                    
                    HStack(spacing: 8) {
                        
                        Image(
                            systemName: "sun.max.fill"
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
                        
                        Text("Dawnly")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        
                        Circle()
                            .fill(
                                Color.dawnlyOrange
                            )
                            .frame(
                                width: 6,
                                height: 6
                            )
                        
                        Text("FOCUSING")
                            .font(
                                .system(
                                    size: 9,
                                    weight: .bold
                                )
                            )
                            .tracking(1.1)
                            .foregroundStyle(
                                Color.dawnlyOrange
                            )
                    }
                }
                
                Spacer()
                    .frame(height: 18)
                
                // MARK: Countdown
                
                Text(
                    timerInterval:
                        context.state.startDate
                    ...
                    context.state.endDate,
                    countsDown: true
                )
                .font(
                    .system(
                        size: 46,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(
                    Color.dawnlyOrange
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                
                Spacer()
                    .frame(height: 7)
                
                // MARK: Status
                
                HStack(
                    alignment: .center,
                    spacing: 6
                ) {
                    
                    Circle()
                        .fill(
                            Color.dawnlyOrange
                        )
                        .frame(
                            width: 6,
                            height: 6
                        )
                    
                    Text("Stay focused.")
                        .font(
                            .system(
                                size: 13,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                
                Spacer()
                    .frame(height: 16)
                
                // MARK: Progress
                
                ProgressView(
                    timerInterval:
                        context.state.startDate
                    ...
                    context.state.endDate,
                    countsDown: false
                )
                .progressViewStyle(
                    DawnlyLiveActivityProgressStyle()
                )
                .frame(height: 5)
            }
            .padding(
                .horizontal,
                22
            )
            .padding(
                .vertical,
                18
            )
            .activityBackgroundTint(
                Color(.systemBackground)
            )
            .activitySystemActionForegroundColor(
                Color.dawnlyOrange
            )
            
        } dynamicIsland: { context in
            
            DynamicIsland {
                
                // =========================================================
                // MARK: Expanded Leading
                // =========================================================
                
                DynamicIslandExpandedRegion(
                    .leading
                ) {
                    
                    HStack(
                        alignment: .center,
                        spacing: 7
                    ) {
                        
                        Image(
                            systemName:
                                "sun.max.fill"
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
                        
                        Text("Dawnly")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .lineLimit(1)
                    }
                    .padding(
                        .leading,
                        12
                    )
                }
                
                // =========================================================
                // MARK: Expanded Trailing
                // =========================================================
                
                DynamicIslandExpandedRegion(
                    .trailing
                ) {
                    
                    HStack(
                        alignment: .center,
                        spacing: 5
                    ) {
                        
                        Text("FOCUS")
                            .font(
                                .system(
                                    size: 9,
                                    weight: .bold
                                )
                            )
                            .tracking(1.0)
                            .foregroundStyle(
                                Color.dawnlyOrange
                            )
                        
                        Circle()
                            .fill(
                                Color.dawnlyOrange
                            )
                            .frame(
                                width: 6,
                                height: 6
                            )
                    }
                    .padding(
                        .trailing,
                        12
                    )
                }
                
                // =========================================================
                // MARK: Expanded Bottom
                // =========================================================
                
                DynamicIslandExpandedRegion(
                    .bottom
                ) {
                    
                    VStack(
                        alignment: .center,
                        spacing: 10
                    ) {
                        
                        // Countdown
                        
                        Text(
                            timerInterval:
                                context.state.startDate
                            ...
                            context.state.endDate,
                            countsDown: true
                        )
                        .font(
                            .system(
                                size: 32,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(
                            Color.dawnlyOrange
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .center
                        )
                        
                        // Progress bar
                        
                        ProgressView(
                            timerInterval:
                                context.state.startDate
                            ...
                            context.state.endDate,
                            countsDown: false
                        )
                        .progressViewStyle(
                            DawnlyLiveActivityProgressStyle()
                        )
                        .frame(height: 5)
                        .padding(
                            .horizontal,
                            28
                        )
                        
                        // Bottom status
                        
                        HStack(
                            alignment: .center,
                            spacing: 0
                        ) {
                            
                            HStack(spacing: 6) {
                                
                                Circle()
                                    .fill(
                                        Color.dawnlyOrange
                                    )
                                    .frame(
                                        width: 6,
                                        height: 6
                                    )
                                
                                Text("Stay focused")
                                    .font(
                                        .system(
                                            size: 11,
                                            weight: .medium
                                        )
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }
                            
                            Spacer()
                            
                            Text("FOCUS SESSION")
                                .font(
                                    .system(
                                        size: 9,
                                        weight: .bold
                                    )
                                )
                                .tracking(0.9)
                                .foregroundStyle(
                                    Color.dawnlyOrange
                                )
                        }
                        .padding(
                            .horizontal,
                            28
                        )
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .top,
                        4
                    )
                    .padding(
                        .bottom,
                        6
                    )
                }
                
                            } compactLeading: {

                                // =========================================================
                                // MARK: Compact Leading
                                // =========================================================

                                HStack(spacing: 0) {

                                    Spacer(
                                        minLength: 0
                                    )

                                    Image(
                                        systemName: "timer"
                                    )
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(
                                        Color.dawnlyOrange
                                    )
                                }
                                .frame(
                                    width: 28,
                                    height: 20,
                                    alignment: .trailing
                                )

                            } compactTrailing: {

                                // =========================================================
                                // MARK: Compact Trailing
                                // =========================================================

                                Text(
                                    context.state.endDate,
                                    style: .timer
                                )
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )
                                .monospacedDigit()
                                .foregroundStyle(
                                    Color.dawnlyOrange
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(
                                    width: 42,
                                    height: 20,
                                    alignment: .leading
                                )

                            } minimal: {

                                // =========================================================
                                // MARK: Minimal
                                // =========================================================

                                Image(
                                    systemName: "timer"
                                )
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    Color.dawnlyOrange
                                )
                                .frame(
                                    width: 20,
                                    height: 20,
                                    alignment: .center
                                )
                            }

        }
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

