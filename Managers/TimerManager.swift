import Foundation
import Observation
import ActivityKit
import WidgetKit

enum TimerPreset {
    case twentyFive
    case fifty
    case custom
}

@Observable
final class TimerManager {

    // MARK: - Public State

    var isRunning = false

    var duration: TimeInterval = 25 * 60
    var timeRemaining: TimeInterval = 25 * 60

    var selectedDuration: TimeInterval = 25 * 60
    var selectedPreset: TimerPreset = .twentyFive

    // MARK: - Internal State

    private var timer: Timer?
    private var startDate: Date?
    private var endDate: Date?

    // MARK: - Live Activity

    private var liveActivity:
        Activity<DawnlyActivityAttributes>?

    // MARK: - Session Completion

    var onSessionCompleted: ((FocusSession) -> Void)?

    var notificationsEnabled = true
    var notificationSoundEnabled = true

    // MARK: - Initialization

    init() {

        let savedDuration =
            UserDefaults.standard.integer(
                forKey: "defaultFocusDuration"
            )

        let defaultMinutes =
            savedDuration > 0
            ? savedDuration
            : 25

        let defaultDuration =
            TimeInterval(
                defaultMinutes * 60
            )

        duration = defaultDuration
        timeRemaining = defaultDuration
        selectedDuration = defaultDuration

        switch defaultMinutes {

        case 25:
            selectedPreset = .twentyFive

        case 50:
            selectedPreset = .fifty

        default:
            selectedPreset = .custom
        }

        restoreRunningSession()
    }

    // MARK: - Start

    @discardableResult
    func start() -> Date {

        start(
            duration: selectedDuration
        )
    }

    @discardableResult
    func start(
        duration: TimeInterval
    ) -> Date {

        // Stop any existing local timer.
        timer?.invalidate()
        timer = nil

        // End any previous Live Activity.
        endCurrentLiveActivity()

        // Clear old state.
        startDate = nil
        endDate = nil
        isRunning = false

        // Store duration.
        self.duration = duration
        self.selectedDuration = duration

        let now = Date()

        let newEndDate =
            now.addingTimeInterval(
                duration
            )

        startDate = now
        endDate = newEndDate

        timeRemaining = duration
        isRunning = true

        // Persist running session.
        DawnlySharedState.saveRunningSession(
            startDate: now,
            endDate: newEndDate
        )

        // Schedule notification.
        if notificationsEnabled {

            NotificationManager.shared
                .scheduleSessionCompletion(
                    at: newEndDate,
                    playSound:
                        notificationSoundEnabled
                )
        }

        // Start Live Activity.
        startLiveActivity(
            startDate: now,
            endDate: newEndDate
        )

        // Refresh widgets.
        WidgetCenter.shared.reloadAllTimelines()

        // Start local countdown.
        startLocalTimer()

        return newEndDate
    }

    // MARK: - Restore Running Session

    private func restoreRunningSession() {

        guard let runningSession =
            DawnlySharedState.runningSession()
        else {
            return
        }

        let now = Date()

        // Session already expired.
        guard runningSession.endDate > now else {

            DawnlySharedState.clearRunningSession()

            return
        }

        startDate =
            runningSession.startDate

        endDate =
            runningSession.endDate

        duration =
            runningSession.endDate
                .timeIntervalSince(
                    runningSession.startDate
                )

        selectedDuration =
            duration

        timeRemaining =
            runningSession.endDate
                .timeIntervalSinceNow

        isRunning = true

        // Restore local timer.
        startLocalTimer()

        // Restore Live Activity.
        restoreLiveActivity(
            startDate:
                runningSession.startDate,
            endDate:
                runningSession.endDate
        )
    }

    // MARK: - Local Timer

    private func startLocalTimer() {

        timer?.invalidate()
        timer = nil

        timer =
            Timer.scheduledTimer(
                withTimeInterval: 1,
                repeats: true
            ) { [weak self] _ in

                self?.updateRemainingTime()
            }
    }

    // MARK: - Live Activity Start

    private func startLiveActivity(
        startDate: Date,
        endDate: Date
    ) {

        guard ActivityAuthorizationInfo()
            .areActivitiesEnabled
        else {

            print(
                "Dawnly: Live Activities are disabled."
            )

            return
        }

        let attributes =
            DawnlyActivityAttributes(
                sessionDuration:
                    duration
            )

        let state =
            DawnlyActivityAttributes.ContentState(
                startDate:
                    startDate,
                endDate:
                    endDate
            )

        do {

            let activity =
                try Activity.request(
                    attributes:
                        attributes,
                    content:
                        .init(
                            state:
                                state,
                            staleDate:
                                endDate
                        ),
                    pushType:
                        nil
                )

            liveActivity =
                activity

            print(
                "Dawnly: Live Activity started: \(activity.id)"
            )

        } catch {

            print(
                "Dawnly: Live Activity failed: \(error)"
            )
        }
    }

    // MARK: - Restore Live Activity

    private func restoreLiveActivity(
        startDate: Date,
        endDate: Date
    ) {

        guard liveActivity == nil
        else {
            return
        }

        // Check for an existing Dawnly Live Activity.
        for activity in Activity<
            DawnlyActivityAttributes
        >.activities {

            liveActivity =
                activity

            print(
                "Dawnly: Existing Live Activity restored: \(activity.id)"
            )

            return
        }

        // No existing activity.
        startLiveActivity(
            startDate:
                startDate,
            endDate:
                endDate
        )
    }

    // MARK: - Update Live Activity

    private func updateLiveActivity() {

        guard
            let activity = liveActivity,
            let startDate,
            let endDate
        else {
            return
        }

        let state =
            DawnlyActivityAttributes.ContentState(
                startDate:
                    startDate,
                endDate:
                    endDate
            )

        Task {

            await activity.update(
                ActivityContent(
                    state:
                        state,
                    staleDate:
                        endDate
                )
            )
        }
    }

    // MARK: - End Live Activity

    private func endCurrentLiveActivity() {

        guard let activity =
                liveActivity
        else {
            return
        }

        liveActivity = nil

        Task {

            await activity.end(
                nil,
                dismissalPolicy:
                    .immediate
            )

            print(
                "Dawnly: Live Activity ended: \(activity.id)"
            )
        }
    }

    // MARK: - Update Timer

    private func updateRemainingTime() {

        guard
            isRunning,
            let endDate
        else {
            return
        }

        let remaining =
            endDate.timeIntervalSinceNow

        if remaining <= 0 {

            if let session =
                finish() {

                onSessionCompleted?(
                    session
                )
            }

        } else {

            timeRemaining =
                remaining

            // Keep Live Activity state synchronized
            // while the app is active.
            updateLiveActivity()
        }
    }

    // MARK: - Finish

    func finish() -> FocusSession? {

        guard
            let startDate,
            let endDate
        else {
            return nil
        }

        timer?.invalidate()
        timer = nil

        isRunning = false

        // Reset timer display.
        timeRemaining =
            selectedDuration

        // End Live Activity.
        endCurrentLiveActivity()

        // Clear persisted session.
        DawnlySharedState.clearRunningSession()

        // Refresh widgets.
        WidgetCenter.shared.reloadAllTimelines()

        // Clear dates.
        self.startDate = nil
        self.endDate = nil

        return FocusSession(
            startDate:
                startDate,
            endDate:
                endDate,
            duration:
                duration,
            completed:
                true
        )
    }

    // MARK: - Cancel

    func cancel() {

        timer?.invalidate()
        timer = nil

        isRunning = false

        endCurrentLiveActivity()

        DawnlySharedState.clearRunningSession()

        WidgetCenter.shared.reloadAllTimelines()

        startDate = nil
        endDate = nil

        timeRemaining =
            selectedDuration
    }

    // MARK: - Progress

    var progress: Double {

        guard duration > 0
        else {
            return 0
        }

        return min(
            max(
                1 -
                (
                    timeRemaining /
                    duration
                ),
                0
            ),
            1
        )
    }

    // MARK: - Formatted Time

    var formattedTime: String {

        let totalSeconds =
            max(
                Int(timeRemaining),
                0
            )

        let minutes =
            totalSeconds / 60

        let seconds =
            totalSeconds % 60

        return String(
            format:
                "%02d:%02d",
            minutes,
            seconds
        )
    }

    // MARK: - Refresh

    func refresh() {

        if !isRunning {

            restoreRunningSession()

            return
        }

        updateRemainingTime()
    }
}
