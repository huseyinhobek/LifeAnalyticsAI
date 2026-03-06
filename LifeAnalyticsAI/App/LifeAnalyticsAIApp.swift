// MARK: - App

import SwiftUI
import SwiftData

@main
struct LifeAnalyticsAIApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @State private var router = NavigationRouter()
    @StateObject private var dependencyContainer = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            AppRootView(router: router)
                .environmentObject(dependencyContainer)
                .task {
                    do {
                        _ = try await dependencyContainer.healthKitService.requestAuthorization()
                    } catch {
                        AppLogger.health.error("HealthKit authorization failed: \(error.localizedDescription)")
                    }
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
