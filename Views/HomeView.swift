import SwiftUI
import SwiftData
import WidgetKit
import UIKit

// MARK: - Dawnly Theme

private extension Color {

    static let dawnlyOrange = Color(
        red: 1.0,
        green: 0.55,
        blue: 0.15
    )
}

// MARK: - Home View

struct HomeView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.scenePhase)
    private var scenePhase

    // MARK: - Settings

    @AppStorage("defaultFocusDuration")
    private var defaultFocusDuration = 25

    @AppStorage("keepScreenAwake")
    private var keepScreenAwake = false

    @AppStorage("sessionCompletionNotifications")
    private var sessionCompletionNotifications = true

    @AppStorage("notificationSound")
    private var notificationSound = true

    // MARK: - Timer

    @State private var timerManager = TimerManager()

    @State private var customMinutes = 25

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 0) {

                // =========================================================
                // MARK: Header
                // =========================================================

                headerView

                Spacer()
                    .frame(height: 32)

                // =========================================================
                // MARK: Duration Selection
                // =========================================================

                if !timerManager.isRunning {
                    durationSelectionView
                }

                // =========================================================
                // MARK: Spacing Before Timer
                // =========================================================

                Spacer()
                    .frame(
                        height: timerManager.isRunning ? 28 : 24
                    )

                // =========================================================
                // MARK: Timer
                // =========================================================

                timerView

                Spacer()
                    .frame(height: 26)

                // =========================================================
                // MARK: Action Button
                // =========================================================

                actionButton

                Spacer()
                    .frame(height: 24)

                // =========================================================
                // MARK: Daily Progress
                // =========================================================

                DailyProgressView(
                    modelContext: modelContext
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        )

        // =============================================================
        // MARK: Lifecycle
        // =============================================================

        .onAppear {

            UIApplication.shared.isIdleTimerDisabled =
                keepScreenAwake

            applyDefaultDuration()

            timerManager.onSessionCompleted = { session in

                modelContext.insert(session)

                do {

                    try modelContext.save()

                    print(
                        "Dawnly: Focus session saved successfully."
                    )

                } catch {

                    print(
                        "Dawnly: Failed to save focus session: \(error)"
                    )
                }

                NotificationManager.shared
                    .cancelSessionCompletion()

                WidgetCenter.shared
                    .reloadTimelines(
                        ofKind: "DawnlyWidget"
                    )
            }

            timerManager.notificationsEnabled =
                sessionCompletionNotifications

            timerManager.notificationSoundEnabled =
                notificationSound

            timerManager.refresh()
        }

        // =============================================================
        // MARK: Screen Awake Setting
        // =============================================================

        .onChange(
            of: keepScreenAwake
        ) { _, newValue in

            UIApplication.shared.isIdleTimerDisabled =
                newValue
        }

        // =============================================================
        // MARK: Default Duration Setting
        // =============================================================

        .onChange(
            of: defaultFocusDuration
        ) { _, _ in

            if !timerManager.isRunning {
                applyDefaultDuration()
            }
        }

        // =============================================================
        // MARK: Notification Setting
        // =============================================================

        .onChange(
            of: sessionCompletionNotifications
        ) { _, newValue in

            timerManager.notificationsEnabled =
                newValue

            if !newValue {

                NotificationManager.shared
                    .cancelSessionCompletion()
            }
        }

        // =============================================================
        // MARK: Notification Sound Setting
        // =============================================================

        .onChange(
            of: notificationSound
        ) { _, newValue in

            timerManager.notificationSoundEnabled =
                newValue
        }

        // =============================================================
        // MARK: Scene Lifecycle
        // =============================================================

        .onChange(
            of: scenePhase
        ) { _, newPhase in

            switch newPhase {

            case .active:

                timerManager.refresh()

                UIApplication.shared.isIdleTimerDisabled =
                    keepScreenAwake

            case .background:

                if !keepScreenAwake {

                    UIApplication.shared.isIdleTimerDisabled =
                        false
                }

            default:
                break
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {

        VStack(spacing: 7) {

            HStack(spacing: 8) {

                Image(
                    systemName: "sun.max.fill"
                )
                .font(
                    .system(
                        size: 19,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )

                Text("Dawnly")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
            }

            Text("Take a moment to focus.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - Duration Selection

    private var durationSelectionView: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text("Focus duration")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )

            HStack(spacing: 4) {

                HomePresetButton(
                    title: "25 min",
                    isSelected:
                        timerManager.selectedPreset
                        == .twentyFive
                ) {

                    select25Minutes()
                }

                HomePresetButton(
                    title: "50 min",
                    isSelected:
                        timerManager.selectedPreset
                        == .fifty
                ) {

                    select50Minutes()
                }

                HomePresetButton(
                    title: "Custom",
                    isSelected:
                        timerManager.selectedPreset
                        == .custom
                ) {

                    selectCustomDuration()
                }
            }

            if timerManager.selectedPreset == .custom {

                customDurationView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }

    // MARK: - Custom Duration

    private var customDurationView: some View {

        VStack(spacing: 8) {

            customDurationHeader

            Slider(
                value: customMinutesBinding,
                in: 5...180,
                step: 5
            )
            .tint(
                Color.dawnlyOrange
            )
        }
        .padding(14)
        .background(
            Color.dawnlyOrange.opacity(0.07),
            in: RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .transition(
            .opacity.combined(
                with: .move(
                    edge: .top
                )
            )
        )
    }

    // MARK: - Timer View

    private var timerView: some View {

        VStack(spacing: 14) {

            Text(timerStatusText)
                .font(
                    .system(
                        size: 10,
                        weight: .bold
                    )
                )
                .tracking(1.4)
                .foregroundStyle(
                    timerManager.isRunning
                    ? Color.dawnlyOrange
                    : Color.secondary
                )

            ZStack {

                // MARK: Outer Ring

                Circle()
                    .stroke(
                        Color.dawnlyOrange.opacity(0.07),
                        lineWidth: 22
                    )

                // MARK: Background Track

                Circle()
                    .stroke(
                        Color.secondary.opacity(0.10),
                        lineWidth: 14
                    )

                // MARK: Progress

                Circle()
                    .trim(
                        from: 0,
                        to: timerProgress
                    )
                    .stroke(
                        Color.dawnlyOrange,
                        style: StrokeStyle(
                            lineWidth: 14,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(
                        .degrees(-90)
                    )
                    .animation(
                        .linear(duration: 0.8),
                        value: timerProgress
                    )

                // MARK: Inner Surface

                Circle()
                    .fill(
                        Color.dawnlyOrange.opacity(0.025)
                    )
                    .padding(25)

                // MARK: Timer Content

                VStack(spacing: 9) {

                    timerText

                    if timerManager.isRunning {

                        runningTimerLabel

                    } else {

                        Text(sessionDescription)
                            .font(
                                .system(
                                    size: 12,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                Color.secondary
                            )
                    }
                }
            }
            .frame(
                width: 280,
                height: 280
            )
        }
        .animation(
            .easeInOut(duration: 0.25),
            value: timerManager.isRunning
        )
    }

    // MARK: - Running Timer Label

    private var runningTimerLabel: some View {

        HStack(spacing: 5) {

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
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.secondary
                )
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {

        Button {

            handleTimerButton()

        } label: {

            HStack(spacing: 9) {

                Image(
                    systemName:
                        timerManager.isRunning
                        ? "xmark"
                        : "play.fill"
                )
                .font(
                    .system(
                        size: 13,
                        weight: .bold
                    )
                )

                Text(
                    timerManager.isRunning
                    ? "Cancel Session"
                    : "Start Focus"
                )
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(
            DawnlyPrimaryButtonStyle(
                isCancel:
                    timerManager.isRunning
            )
        )
    }

    // MARK: - Timer Status

    private var timerStatusText: String {

        if timerManager.isRunning {
            return "FOCUS SESSION"
        }

        return "READY TO FOCUS"
    }

    // MARK: - Timer Progress

    private var timerProgress: Double {

        let progress =
            timerManager.progress

        return min(
            max(progress, 0),
            1
        )
    }

    // MARK: - Timer Text

    private var timerText: some View {

        let time =
            timerManager.formattedTime

        return Text(time)
            .font(
                .system(
                    size: 50,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .minimumScaleFactor(0.7)
            .lineLimit(1)
    }

    // MARK: - Custom Duration Header

    private var customDurationHeader: some View {

        let text =
            "\(customMinutes) min"

        return HStack {

            Text("Duration")
                .font(.subheadline)

            Spacer()

            Text(text)
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )
        }
    }

    // MARK: - Custom Minutes Binding

    private var customMinutesBinding:
        Binding<Double> {

        Binding(
            get: {
                Double(customMinutes)
            },
            set: { newValue in

                let minutes =
                    Int(newValue)

                updateCustomDuration(
                    minutes
                )
            }
        )
    }

    // MARK: - Select 25 Minutes

    private func select25Minutes() {

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {

            timerManager.selectedPreset =
                .twentyFive

            let duration =
                TimeInterval(25 * 60)

            timerManager.selectedDuration =
                duration

            timerManager.duration =
                duration

            timerManager.timeRemaining =
                duration

            customMinutes =
                25
        }
    }

    // MARK: - Select 50 Minutes

    private func select50Minutes() {

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {

            timerManager.selectedPreset =
                .fifty

            let duration =
                TimeInterval(50 * 60)

            timerManager.selectedDuration =
                duration

            timerManager.duration =
                duration

            timerManager.timeRemaining =
                duration

            customMinutes =
                50
        }
    }

    // MARK: - Select Custom Duration

    private func selectCustomDuration() {

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {

            timerManager.selectedPreset =
                .custom

            updateCustomDuration(
                customMinutes
            )
        }
    }

    // MARK: - Custom Duration Update

    private func updateCustomDuration(
        _ minutes: Int
    ) {

        let safeMinutes =
            min(
                max(minutes, 5),
                180
            )

        customMinutes =
            safeMinutes

        let duration =
            TimeInterval(
                safeMinutes * 60
            )

        timerManager.selectedDuration =
            duration

        timerManager.duration =
            duration

        timerManager.timeRemaining =
            duration
    }

    // MARK: - Apply Default Duration

    private func applyDefaultDuration() {

        switch defaultFocusDuration {

        case 25:

            timerManager.selectedPreset =
                .twentyFive

            let duration =
                TimeInterval(25 * 60)

            timerManager.selectedDuration =
                duration

            timerManager.duration =
                duration

            timerManager.timeRemaining =
                duration

            customMinutes =
                25

        case 50:

            timerManager.selectedPreset =
                .fifty

            let duration =
                TimeInterval(50 * 60)

            timerManager.selectedDuration =
                duration

            timerManager.duration =
                duration

            timerManager.timeRemaining =
                duration

            customMinutes =
                50

        default:

            timerManager.selectedPreset =
                .custom

            let duration =
                TimeInterval(
                    defaultFocusDuration * 60
                )

            timerManager.selectedDuration =
                duration

            timerManager.duration =
                duration

            timerManager.timeRemaining =
                duration

            customMinutes =
                defaultFocusDuration
        }
    }

    // MARK: - Session Description

    private var sessionDescription: String {

        switch timerManager.selectedPreset {

        case .twentyFive:

            return "25 minute session"

        case .fifty:

            return "50 minute session"

        case .custom:

            return "\(customMinutes) minute session"
        }
    }

    // MARK: - Timer Button

    private func handleTimerButton() {

        if timerManager.isRunning {

            withAnimation(
                .easeInOut(duration: 0.25)
            ) {

                timerManager.cancel()
            }

            NotificationManager.shared
                .cancelSessionCompletion()

            return
        }

        timerManager.start()
    }
}

// MARK: - Preset Button

private struct HomePresetButton: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(
            action: action
        ) {

            Text(title)
                .font(
                    .system(
                        size: 14,
                        weight:
                            isSelected
                            ? .semibold
                            : .medium
                    )
                )
                .foregroundStyle(
                    isSelected
                    ? Color.white
                    : Color.primary
                )
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 44)
                .background {

                    if isSelected {

                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(
                            Color.dawnlyOrange
                        )
                        .shadow(
                            color:
                                Color.dawnlyOrange
                                    .opacity(0.20),
                            radius: 8,
                            y: 3
                        )

                    } else {

                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(
                            Color.clear
                        )
                    }
                }
        }
        .buttonStyle(.plain)
        .contentShape(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
        .animation(
            .easeInOut(duration: 0.18),
            value: isSelected
        )
    }
}

// MARK: - Primary Button Style

private struct DawnlyPrimaryButtonStyle:
    ButtonStyle {

    let isCancel: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .foregroundStyle(
                isCancel
                ? Color.primary
                : Color.white
            )
            .background(
                isCancel
                ? Color.secondary.opacity(
                    configuration.isPressed
                    ? 0.16
                    : 0.10
                )
                : Color.dawnlyOrange.opacity(
                    configuration.isPressed
                    ? 0.75
                    : 1.0
                ),
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .scaleEffect(
                configuration.isPressed
                ? 0.98
                : 1.0
            )
            .animation(
                .easeOut(duration: 0.15),
                value:
                    configuration.isPressed
            )
    }
}

// MARK: - Daily Progress

private struct DailyProgressView: View {

    let modelContext: ModelContext

    private var todaySessions:
        [FocusSession] {

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

            return try modelContext.fetch(
                descriptor
            )

        } catch {

            print(
                "Dawnly: Daily progress fetch error: \(error)"
            )

            return []
        }
    }

    private var totalFocusTime:
        TimeInterval {

        todaySessions.reduce(0) {
            $0 + $1.duration
        }
    }

    var body: some View {

        HStack(spacing: 14) {

            DailyProgressMetric(
                icon: "clock.fill",
                title: "Today",
                value: formattedFocusTime
            )

            Rectangle()
                .fill(
                    Color.secondary.opacity(0.12)
                )
                .frame(
                    width: 1,
                    height: 34
                )

            DailyProgressMetric(
                icon: "checkmark.circle.fill",
                title: "Sessions",
                value:
                    "\(todaySessions.count)"
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
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

    // MARK: - Formatting

    private var formattedFocusTime: String {

        let totalMinutes =
            Int(
                totalFocusTime / 60
            )

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

// MARK: - Daily Progress Metric

private struct DailyProgressMetric:
    View {

    let icon: String
    let title: String
    let value: String

    var body: some View {

        HStack(spacing: 9) {

            Image(
                systemName: icon
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

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 10,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.secondary
                    )

                Text(value)
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Preview

#Preview {

    HomeView()
        .modelContainer(
            for: FocusSession.self
        )
}
