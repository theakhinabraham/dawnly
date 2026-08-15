import ActivityKit
import Foundation

struct DawnlyActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {

        let startDate: Date
        let endDate: Date
    }

    let sessionDuration: TimeInterval
}
