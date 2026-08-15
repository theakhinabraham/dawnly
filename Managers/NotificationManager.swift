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
                    options: [.alert, .sound, .badge]
                )

        } catch {

            print(
                "Notification permission error: \(error)"
            )
        }
    }

    // MARK: - Schedule Session Complete

    func scheduleSessionCompletion(
        at date: Date
    ) {

        let content = UNMutableNotificationContent()

        content.title = "Focus Complete"
        content.body = "Great work. Time for a break."
        content.sound = .default

        let interval = date.timeIntervalSinceNow

        guard interval > 0 else {
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "dawnly.focus.complete",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current()
            .add(request) { error in

                if let error {
                    print(
                        "Notification scheduling error: \(error)"
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
    }
}
