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

    // MARK: - Start

    @discardableResult
    func start() -> Date {
        start(duration: selectedDuration)
    }

    @discardableResult
    func start(
        duration: TimeInterval
    ) -> Date {

        // Stop the local timer if one is already running.
        timer?.invalidate()
        timer = nil

        // End only Dawnly's current Live Activity.
        endCurrentLiveActivity()

        // Clear previous timer state.
        startDate = nil
        endDate = nil

        isRunning = false

        self.duration = duration
        self.selectedDuration = duration

        let now = Date()
        let newEndDate = now.addingTimeInterval(duration)

        startDate = now
        endDate = newEndDate

        timeRemaining = duration
        isRunning = true

        // Save running session for the widget.
        DawnlySharedState.saveRunningSession(
            startDate: now,
            endDate: newEndDate
        )

        // Start the Live Activity.
        startLiveActivity(
            startDate: now,
            endDate: newEndDate
        )

        // Refresh the Home Screen widget.
        WidgetCenter.shared.reloadAllTimelines()

        // Start local timer.
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in

            self?.updateRemainingTime()
        }

        return newEndDate
    }

    // MARK: - Live Activity
    // Start

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
                sessionDuration: duration
            )

        let state =
            DawnlyActivityAttributes.ContentState(
                startDate: startDate,
                endDate: endDate
            )

        do {

            let activity = try Activity.request(
                attributes: attributes,
                content: .init(
                    state: state,
                    staleDate: endDate
                ),
                pushType: nil
            )

            liveActivity = activity

            print(
                "Dawnly Live Activity started: \(activity.id)"
            )

        } catch {

            print(
                "Dawnly Live Activity failed: \(error)"
            )
        }
    }

    // MARK: - Live Activity
    // End Current Activity

    private func endCurrentLiveActivity() {

        guard let activity = liveActivity else {
            return
        }

        liveActivity = nil

        Task {

            await activity.end(
                nil,
                dismissalPolicy: .immediate
            )

            print(
                "Dawnly Live Activity ended: \(activity.id)"
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

            if let session = finish() {
                onSessionCompleted?(session)
            }

        } else {

            timeRemaining = remaining
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

        // Stop local timer.
        timer?.invalidate()
        timer = nil

        // Update state.
        isRunning = false
        timeRemaining = 0

        // End only our current Live Activity.
        endCurrentLiveActivity()

        // Clear shared running-session state.
        DawnlySharedState.clearRunningSession()

        // Refresh Home Screen widget.
        WidgetCenter.shared.reloadAllTimelines()

        // Clear dates.
        self.startDate = nil
        self.endDate = nil

        // Create completed session.
        return FocusSession(
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            completed: true
        )
    }

    // MARK: - Cancel

    func cancel() {

        // Stop local timer.
        timer?.invalidate()
        timer = nil

        // Stop running state.
        isRunning = false

        // End ONLY our Live Activity.
        endCurrentLiveActivity()

        // Clear shared running-session state.
        DawnlySharedState.clearRunningSession()

        // Refresh Home Screen widget.
        WidgetCenter.shared.reloadAllTimelines()

        // Clear dates.
        startDate = nil
        endDate = nil

        // Reset displayed time.
        timeRemaining = selectedDuration
    }

    // MARK: - Progress

    var progress: Double {

        guard duration > 0 else {
            return 0
        }

        return 1 - (
            timeRemaining / duration
        )
    }

    // MARK: - Formatted Time

    var formattedTime: String {

        let minutes =
            Int(timeRemaining) / 60

        let seconds =
            Int(timeRemaining) % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }

    // MARK: - Refresh

    func refresh() {

        guard isRunning else {
            return
        }

        updateRemainingTime()
    }
}
