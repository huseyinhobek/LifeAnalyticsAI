// MARK: - Tests.SettingsViewModelNotification

import Foundation
import XCTest
@testable import LifeAnalyticsAI

@MainActor
final class SettingsViewModelNotificationTests: XCTestCase {
    func testPersistNotificationStateDoesNotScheduleWhenPermissionDenied() async {
        let manager = UserDefaultsManager()
        manager.notificationsEnabled = true
        manager.weeklyReportEnabled = true
        manager.dataCollectionStartDate = nil

        let notificationService = MockNotificationService(permissionGranted: false)
        let viewModel = SettingsViewModel(
            userDefaultsManager: manager,
            notificationService: notificationService,
            generatePredictionTextUseCase: StubPredictionTextUseCase(text: "3.8 tahmin")
        )

        await viewModel.persistNotificationState()

        XCTAssertEqual(notificationService.requestPermissionCallCount, 1)
        XCTAssertEqual(notificationService.morningScheduleCallCount, 0)
        XCTAssertEqual(notificationService.eveningScheduleCallCount, 0)
        XCTAssertEqual(notificationService.weeklyScheduleCallCount, 0)
        XCTAssertEqual(viewModel.statusMessage, "Bildirim izni verilmedi. Ayarlardan izin verebilirsin.")
    }

    func testPersistNotificationStateSchedulesAllWhenEnabledAndWeeklyOn() async {
        let manager = UserDefaultsManager()
        manager.notificationsEnabled = true
        manager.weeklyReportEnabled = true
        manager.dataCollectionStartDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())

        let notificationService = MockNotificationService(permissionGranted: true)
        let viewModel = SettingsViewModel(
            userDefaultsManager: manager,
            notificationService: notificationService,
            generatePredictionTextUseCase: StubPredictionTextUseCase(text: "3.9 puan, son 7 gun pattern")
        )

        await viewModel.persistNotificationState()

        XCTAssertEqual(notificationService.requestPermissionCallCount, 1)
        XCTAssertEqual(notificationService.cancelAllCallCount, 1)
        XCTAssertEqual(notificationService.morningScheduleCallCount, 1)
        XCTAssertEqual(notificationService.eveningScheduleCallCount, 1)
        XCTAssertEqual(notificationService.weeklyScheduleCallCount, 1)

        XCTAssertTrue((6...10).contains(notificationService.lastMorningComponents?.hour ?? -1))
        XCTAssertEqual(notificationService.lastMorningComponents?.minute, AppConstants.Notifications.morningMinute)
        XCTAssertTrue((19...22).contains(notificationService.lastEveningComponents?.hour ?? -1))
        XCTAssertEqual(notificationService.lastEveningComponents?.minute, AppConstants.Notifications.eveningMinute)
        XCTAssertEqual(notificationService.lastWeeklyComponents?.weekday, AppConstants.Notifications.weeklyReportDay)
        XCTAssertTrue((17...21).contains(notificationService.lastWeeklyComponents?.hour ?? -1))
        XCTAssertEqual(notificationService.lastWeeklyComponents?.minute, AppConstants.Notifications.weeklyReportMinute)

        XCTAssertNotNil(viewModel.statusMessage)
        XCTAssertTrue(viewModel.statusMessage?.contains("optimize") ?? false)
    }
}

private final class MockNotificationService: NotificationServiceProtocol {
    private(set) var requestPermissionCallCount = 0
    private(set) var cancelAllCallCount = 0
    private(set) var morningScheduleCallCount = 0
    private(set) var eveningScheduleCallCount = 0
    private(set) var weeklyScheduleCallCount = 0

    private let permissionGranted: Bool

    private(set) var lastMorningComponents: DateComponents?
    private(set) var lastEveningComponents: DateComponents?
    private(set) var lastWeeklyComponents: DateComponents?

    init(permissionGranted: Bool) {
        self.permissionGranted = permissionGranted
    }

    func requestPermission() async throws -> Bool {
        requestPermissionCallCount += 1
        return permissionGranted
    }

    func scheduleMorning(at components: DateComponents, streakDays: Int, predictionText: String?) async throws {
        _ = streakDays
        _ = predictionText
        morningScheduleCallCount += 1
        lastMorningComponents = components
    }

    func scheduleEvening(at components: DateComponents, moodCheckInsThisWeek: Int) async throws {
        _ = moodCheckInsThisWeek
        eveningScheduleCallCount += 1
        lastEveningComponents = components
    }

    func scheduleWeekly(at components: DateComponents, trackedDays: Int) async throws {
        _ = trackedDays
        weeklyScheduleCallCount += 1
        lastWeeklyComponents = components
    }

    func cancelAll() async {
        cancelAllCallCount += 1
    }
}

private struct StubPredictionTextUseCase: GeneratePredictionTextUseCaseProtocol {
    let text: String?

    func execute(for referenceDate: Date) async throws -> String? {
        _ = referenceDate
        return text
    }
}
