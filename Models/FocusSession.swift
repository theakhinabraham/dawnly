import Foundation
import SwiftData

@Model
final class FocusSession {

    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var completed: Bool

    init(
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        completed: Bool = true
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.completed = completed
    }
}
