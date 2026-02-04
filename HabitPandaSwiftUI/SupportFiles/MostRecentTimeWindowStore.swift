import Foundation

final class MostRecentTimeWindowStore {
    static let shared = MostRecentTimeWindowStore()
    private let defaults = UserDefaults.standard
    private let dateKey = "mrw_lastDate"
    private let idKey = "mrw_lastTimeWindowID"

    private init() {}

    struct Entry: Equatable {
        let date: Date
        let timeWindowID: UUID
    }

    func getMostRecent() -> Entry? {
        guard let idString = defaults.string(forKey: idKey),
              let id = UUID(uuidString: idString) else { return nil }
        let timeInterval = defaults.double(forKey: dateKey)
        guard timeInterval != 0 else { return nil }
        let date = Date(timeIntervalSince1970: timeInterval).stripTime()
        return Entry(date: date, timeWindowID: id)
    }

    func markCompleted(timeWindowID: UUID, on date: Date) {
        defaults.set(date.stripTime().timeIntervalSince1970, forKey: dateKey)
        defaults.set(timeWindowID.uuidString, forKey: idKey)
    }

    func unmarkIfMatches(timeWindowID: UUID, on date: Date) {
        guard let entry = getMostRecent(),
              entry.date == date.stripTime(),
              entry.timeWindowID == timeWindowID else { return }
        reset()
    }

    func reset() {
        defaults.removeObject(forKey: dateKey)
        defaults.removeObject(forKey: idKey)
    }
}
