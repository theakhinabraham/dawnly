import Foundation
import SwiftUI

// MARK: - Goal Settings

enum GoalSettings {

    // MARK: Daily Focus Goal

    static let defaultFocusGoalMinutes = 60

    static let minimumFocusGoalMinutes = 15

    static let maximumFocusGoalMinutes = 480

    static let focusGoalStep = 15

    // MARK: Daily Session Goal

    static let defaultSessionGoal = 3

    static let minimumSessionGoal = 1

    static let maximumSessionGoal = 20
}

// MARK: - Goal Display Helpers

extension GoalSettings {

    static func focusGoalLabel(
        minutes: Int
    ) -> String {

        if minutes < 60 {
            return "\(minutes) min"
        }

        let hours = minutes / 60
        let remaining = minutes % 60

        if remaining == 0 {
            return "\(hours) hr"
        }

        return "\(hours) hr \(remaining) min"
    }

    static func focusGoalShortLabel(
        minutes: Int
    ) -> String {

        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remaining = minutes % 60

        if remaining == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remaining)m"
    }
}
