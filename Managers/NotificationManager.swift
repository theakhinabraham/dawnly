import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    // MARK: - Request Permission

    func requestPermission() async {

        do {

            try await UNUserNotificationCenter.current()
                .requestAuthorization(
                    options: [
                        .alert,
                        .sound,
                        .badge
                    ]
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

        let content =
            UNMutableNotificationContent()

        content.title =
            "Focus Complete"

        content.body =
            "Great work. Time for a break."

        // Respect the user's notification sound setting.

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

        UNUserNotificationCenter.current()
            .add(request) { error in

                if let error {

                    print(
                        "Dawnly: Notification scheduling error: \(error)"
                    )

                } else {

                    print(
                        "Dawnly: Focus completion notification scheduled."
                    )
                }
            }
    }

    // MARK: - Cancel

    func cancelSessionCompletion() {

        UNUserNotificationCenter.current()
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
