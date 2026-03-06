// MARK: - Core.Extensions

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? startOfDay
    }

    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }

    var isWeekend: Bool {
        dayOfWeek == 1 || dayOfWeek == 7
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    var shortDateString: String {
        DateFormatters.shortDate.string(from: self)
    }

    var timeString: String {
        DateFormatters.time.string(from: self)
    }

    var relativeDateString: String {
        let calendar = Calendar.current
        let today = Date().startOfDay
        let target = startOfDay
        let dayDiff = calendar.dateComponents([.day], from: target, to: today).day ?? 0

        switch dayDiff {
        case 0:
            return "Bugun"
        case 1:
            return "Dun"
        case let value where value > 1:
            return "\(value) gun once"
        case -1:
            return "Yarin"
        default:
            return shortDateString
        }
    }
}

extension Array where Element == Date {
    var dateRange: ClosedRange<Date>? {
        guard let minDate = self.min(), let maxDate = self.max() else {
            return nil
        }
        return minDate...maxDate
    }
}

private enum DateFormatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
