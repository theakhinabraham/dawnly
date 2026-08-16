import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    // MARK: - Request Permission

    func requestPermission() async {

        do {

            let granted =
                try await UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound,
                            .badge
                        ]
                    )

            print(
                "Dawnly: Notification permission: \(granted)"
            )

        } catch {

            print(
                "Dawnly: Notification permission error: \(error)"
            )
        }
    }

    // MARK: - Schedule Session Completion

    func scheduleSessionCompletion(
        at date: Date,
        playSound: Bool = true
    ) {

        let center =
            UNUserNotificationCenter.current()

        // Remove any previous Dawnly completion notification.
        center.removePendingNotificationRequests(
            withIdentifiers: [
                "dawnly.focus.complete"
            ]
        )

        let content =
            UNMutableNotificationContent()

        content.title =
            "Focus Complete"

        content.body =
            "Great work. Time for a break."

        if playSound {

            content.sound =
                .default

        } else {

            content.sound =
                nil
        }

        let interval =
            date.timeIntervalSinceNow

        guard interval > 0 else {

            print(
                "Dawnly: Notification date is in the past."
            )

            return
        }

        let trigger =
            UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )

        let request =
            UNNotificationRequest(
                identifier:
                    "dawnly.focus.complete",
                content:
                    content,
                trigger:
                    trigger
            )

        center.add(request) { error in

            if let error {

                print(
                    "Dawnly: Notification scheduling error: \(error)"
                )

            } else {

                print(
                    "Dawnly: Focus completion notification scheduled for \(date)"
                )
            }
        }
    }

    // MARK: - Cancel

    func cancelSessionCompletion() {

        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    "dawnly.focus.complete"
                ]
            )

        print(
            "Dawnly: Focus completion notification cancelled."
        )
    }
}
