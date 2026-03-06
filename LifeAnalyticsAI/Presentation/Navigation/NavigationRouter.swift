// MARK: - Presentation.Navigation

import Observation
import SwiftUI

enum AppRoute: Hashable {
    case home
    case moodEntry(preset: Int?)
    case weeklyReport(weekStart: Date)
    case insightDetail(Insight)
    case settings
    case onboarding
    case insightHistory
}

@Observable
final class NavigationRouter {
    var path = NavigationPath()
    var showOnboarding = false
    var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home = 0
        case insights = 1
        case report = 2
        case settings = 3

        var title: String {
            switch self {
            case .home:
                return "Ana Sayfa"
            case .insights:
                return "Icgoruler"
            case .report:
                return "Rapor"
            case .settings:
                return "Ayarlar"
            }
        }

        var icon: String {
            switch self {
            case .home:
                return "house"
            case .insights:
                return "lightbulb"
            case .report:
                return "chart.bar"
            case .settings:
                return "gearshape"
            }
        }
    }

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func goToRoot() {
        path = NavigationPath()
    }
}

struct AppRootView: View {
    @Bindable var router: NavigationRouter
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @State private var userDefaultsManager = UserDefaultsManager()
    @State private var onboardingStep: OnboardingStep = .healthKit

    private enum OnboardingStep {
        case healthKit
        case calendar
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $router.selectedTab) {
                HomeView(viewModel: makeHomeViewModel(), router: router)
                    .tabItem {
                        Label(NavigationRouter.Tab.home.title, systemImage: NavigationRouter.Tab.home.icon)
                    }
                    .tag(NavigationRouter.Tab.home)

                Text("Insights")
                    .tabItem {
                        Label(NavigationRouter.Tab.insights.title, systemImage: NavigationRouter.Tab.insights.icon)
                    }
                    .tag(NavigationRouter.Tab.insights)

                Text("Weekly Report")
                    .tabItem {
                        Label(NavigationRouter.Tab.report.title, systemImage: NavigationRouter.Tab.report.icon)
                    }
                    .tag(NavigationRouter.Tab.report)

                Text("Settings")
                    .tabItem {
                        Label(NavigationRouter.Tab.settings.title, systemImage: NavigationRouter.Tab.settings.icon)
                    }
                    .tag(NavigationRouter.Tab.settings)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .home:
                    HomeView(viewModel: makeHomeViewModel(), router: router)
                case let .moodEntry(preset):
                    MoodEntryView(viewModel: makeMoodEntryViewModel(preset: preset))
                case let .weeklyReport(weekStart):
                    Text("Weekly Report: \(weekStart.formatted(date: .abbreviated, time: .omitted))")
                case let .insightDetail(insight):
                    InsightDetailView(viewModel: makeInsightDetailViewModel(insight: insight))
                case .settings:
                    Text("Settings")
                case .onboarding:
                    Text("Onboarding")
                case .insightHistory:
                    MoodHistoryView(viewModel: MoodHistoryViewModel(fetchMoodEntriesUseCase: dependencyContainer.fetchMoodEntriesUseCase))
                }
            }
            .fullScreenCover(isPresented: $router.showOnboarding) {
                switch onboardingStep {
                case .healthKit:
                    HealthKitPermissionView(
                        onContinue: {
                            onboardingStep = .calendar
                        },
                        onSkip: {
                            onboardingStep = .calendar
                        }
                    )
                case .calendar:
                    CalendarPermissionView(
                        onContinue: completeOnboarding,
                        onSkip: completeOnboarding
                    )
                }
            }
            .task {
                if !userDefaultsManager.hasCompletedOnboarding {
                    onboardingStep = .healthKit
                    router.showOnboarding = true
                }
            }
            .onOpenURL { url in
                guard url.scheme == "lifeanalytics" else { return }
                if url.host == "mood-entry" {
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let preset = components?.queryItems?
                        .first(where: { $0.name == "preset" })?
                        .value
                        .flatMap(Int.init)
                    router.navigate(to: .moodEntry(preset: preset))
                }
            }
        }
    }

    private func completeOnboarding() {
        userDefaultsManager.hasCompletedOnboarding = true
        router.showOnboarding = false
    }

    private func makeMoodEntryViewModel(preset: Int?) -> MoodEntryViewModel {
        let viewModel = MoodEntryViewModel(saveMoodEntryUseCase: dependencyContainer.saveMoodEntryUseCase)
        viewModel.applyPresetMood(value: preset)
        return viewModel
    }

    private func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            generateDailyInsightCardUseCase: dependencyContainer.generateDailyInsightCardUseCase,
            fetchWeeklyReportUseCase: dependencyContainer.fetchWeeklyReportUseCase,
            sleepRepository: dependencyContainer.sleepRepository,
            moodRepository: dependencyContainer.moodRepository,
            calendarRepository: dependencyContainer.calendarRepository
        )
    }

    private func makeInsightDetailViewModel(insight: Insight) -> InsightDetailViewModel {
        InsightDetailViewModel(
            insight: insight,
            updateInsightFeedbackUseCase: dependencyContainer.updateInsightFeedbackUseCase
        )
    }
}
