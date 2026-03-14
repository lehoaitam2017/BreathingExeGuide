import Foundation
import SwiftData

@Model
final class SessionRecord {
    var sessionName: String
    var completedAt: Date
    var durationSeconds: Int

    init(sessionName: String, completedAt: Date, durationSeconds: Int) {
        self.sessionName = sessionName
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
    }
}
