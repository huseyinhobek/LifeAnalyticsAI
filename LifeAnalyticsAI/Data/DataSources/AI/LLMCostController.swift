// MARK: - Data.DataSources.AI

import Foundation

protocol LLMUsageTracking {
    func canConsume(tokens: Int, at date: Date) async -> Bool
    func record(tokens: Int, at date: Date) async
}

protocol LLMResponseCaching {
    func cachedValue(for key: String, now: Date) async -> String?
    func store(_ value: String, for key: String, ttl: TimeInterval, now: Date) async
}

actor LLMUsageTracker: LLMUsageTracking {
    private struct State: Codable {
        var dailyKey: String
        var monthlyKey: String
        var dailyTokens: Int
        var monthlyTokens: Int
    }

    private enum Keys {
        static let usageState = "llm.usage.state"
    }

    private let dailyLimit: Int
    private let monthlyLimit: Int
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let dayFormatter: DateFormatter
    private let monthFormatter: DateFormatter

    init(
        dailyLimit: Int = AppConstants.API.llmDailyTokenLimit,
        monthlyLimit: Int = AppConstants.API.llmMonthlyTokenLimit,
        defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.Storage.userDefaultsSuite),
        calendar: Calendar = .current
    ) {
        self.dailyLimit = dailyLimit
        self.monthlyLimit = monthlyLimit
        self.defaults = defaults ?? .standard
        self.calendar = calendar

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyy-MM-dd"
        self.dayFormatter = dayFormatter

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.locale = Locale(identifier: "en_US_POSIX")
        monthFormatter.dateFormat = "yyyy-MM"
        self.monthFormatter = monthFormatter
    }

    func canConsume(tokens: Int, at date: Date = Date()) async -> Bool {
        guard tokens > 0 else { return true }
        let state = normalizedState(for: date)
        let withinDaily = state.dailyTokens + tokens <= dailyLimit
        let withinMonthly = state.monthlyTokens + tokens <= monthlyLimit
        return withinDaily && withinMonthly
    }

    func record(tokens: Int, at date: Date = Date()) async {
        guard tokens > 0 else { return }
        var state = normalizedState(for: date)
        state.dailyTokens += tokens
        state.monthlyTokens += tokens
        save(state)
    }

    private func normalizedState(for date: Date) -> State {
        var state = loadState()
        let dayKey = dayFormatter.string(from: date)
        let monthKey = monthFormatter.string(from: date)

        if state.dailyKey != dayKey {
            state.dailyKey = dayKey
            state.dailyTokens = 0
        }
        if state.monthlyKey != monthKey {
            state.monthlyKey = monthKey
            state.monthlyTokens = 0
        }

        save(state)
        return state
    }

    private func loadState() -> State {
        guard let data = defaults.data(forKey: Keys.usageState),
              let state = try? JSONDecoder().decode(State.self, from: data) else {
            let now = Date()
            return State(
                dailyKey: dayFormatter.string(from: now),
                monthlyKey: monthFormatter.string(from: now),
                dailyTokens: 0,
                monthlyTokens: 0
            )
        }
        return state
    }

    private func save(_ state: State) {
        guard let encoded = try? JSONEncoder().encode(state) else {
            return
        }
        defaults.set(encoded, forKey: Keys.usageState)
    }
}

actor LLMResponseCache: LLMResponseCaching {
    private struct CacheEntry {
        let value: String
        let expiryDate: Date
    }

    private var storage: [String: CacheEntry] = [:]

    func cachedValue(for key: String, now: Date = Date()) async -> String? {
        guard let entry = storage[key] else { return nil }
        guard entry.expiryDate > now else {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func store(_ value: String, for key: String, ttl: TimeInterval, now: Date = Date()) async {
        guard ttl > 0 else { return }
        storage[key] = CacheEntry(value: value, expiryDate: now.addingTimeInterval(ttl))
    }
}
