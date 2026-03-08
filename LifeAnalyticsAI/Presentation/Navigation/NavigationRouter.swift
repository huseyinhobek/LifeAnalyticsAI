// MARK: - Presentation.Navigation

import Observation
import SwiftUI

enum AppRoute: Hashable {
    case home
    case moodEntry(preset: Int?)
    case dashboard
    case profile
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
                return "tab.home".localized
            case .insights:
                return "tab.insights".localized
            case .report:
                return "tab.report".localized
            case .settings:
                return "tab.settings".localized
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
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var userDefaultsManager = UserDefaultsManager()

    var body: some View {
        rootContent
        .fullScreenCover(isPresented: $router.showOnboarding) {
            OnboardingView(onComplete: completeOnboarding)
        }
        .task {
            if !userDefaultsManager.hasCompletedOnboarding {
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
            } else if url.host == "report" {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    router.selectedTab = .report
                    router.goToRoot()
                }
            }
        }
        .preferredColorScheme(preferredScheme(forTheme: userDefaultsManager.preferredTheme))
    }

    @ViewBuilder
    private var rootContent: some View {
        if isRegularWidth {
            regularLayout
        } else {
            compactLayout
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(NavigationRouter.Tab.allCases, id: \.self) { tab in
                    Button {
                        tabSelectionBinding.wrappedValue = tab
                    } label: {
                        HStack(spacing: 10) {
                            Label(tab.title, systemImage: tab.icon)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if differentiateWithoutColor, tab == router.selectedTab {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("TextPrimary"))
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        tab == router.selectedTab
                            ? Color("SecondaryBlue").opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityLabel(tab.title)
                    .accessibilityValue(tab == router.selectedTab ? "general.selected".localized : "general.not_selected".localized)
                }
            }
            .navigationTitle("Life Analytics")
        } detail: {
            NavigationStack(path: $router.path) {
                destinationView(for: router.selectedTab)
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(for: route)
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var compactLayout: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: tabSelectionBinding) {
                HomeView(viewModel: makeHomeViewModel(), router: router)
                    .tabItem {
                        Label(NavigationRouter.Tab.home.title, systemImage: NavigationRouter.Tab.home.icon)
                    }
                    .tag(NavigationRouter.Tab.home)

                InsightHistoryView(viewModel: makeInsightHistoryViewModel(), router: router)
                    .tabItem {
                        Label(NavigationRouter.Tab.insights.title, systemImage: NavigationRouter.Tab.insights.icon)
                    }
                    .tag(NavigationRouter.Tab.insights)

                DashboardView(viewModel: makeDashboardViewModel(), router: router)
                    .tabItem {
                        Label(NavigationRouter.Tab.report.title, systemImage: NavigationRouter.Tab.report.icon)
                    }
                    .tag(NavigationRouter.Tab.report)

                SettingsView(viewModel: makeSettingsViewModel(), router: router)
                    .tabItem {
                        Label(NavigationRouter.Tab.settings.title, systemImage: NavigationRouter.Tab.settings.icon)
                    }
                    .tag(NavigationRouter.Tab.settings)
            }
            .navigationDestination(for: AppRoute.self) { route in
                routeDestination(for: route)
            }
        }
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private var tabSelectionBinding: Binding<NavigationRouter.Tab> {
        Binding(
            get: { router.selectedTab },
            set: { newTab in
                guard router.selectedTab != newTab else { return }
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    router.selectedTab = newTab
                    router.goToRoot()
                }
            }
        )
    }

    @ViewBuilder
    private func destinationView(for tab: NavigationRouter.Tab) -> some View {
        switch tab {
        case .home:
            HomeView(viewModel: makeHomeViewModel(), router: router)
        case .insights:
            InsightHistoryView(viewModel: makeInsightHistoryViewModel(), router: router)
        case .report:
            DashboardView(viewModel: makeDashboardViewModel(), router: router)
        case .settings:
            SettingsView(viewModel: makeSettingsViewModel(), router: router)
        }
    }

    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView(viewModel: makeHomeViewModel(), router: router)
        case let .moodEntry(preset):
            MoodEntryView(viewModel: makeMoodEntryViewModel(preset: preset))
        case .dashboard:
            DashboardView(viewModel: makeDashboardViewModel(), router: router)
        case .profile:
            ProfileView(viewModel: makeProfileViewModel())
        case let .weeklyReport(weekStart):
            WeeklyReportView(viewModel: makeWeeklyReportViewModel(weekStart: weekStart), router: router)
        case let .insightDetail(insight):
            InsightDetailView(viewModel: makeInsightDetailViewModel(insight: insight))
        case .settings:
            SettingsView(viewModel: makeSettingsViewModel(), router: router)
        case .onboarding:
            Text("onboarding.title".localized)
        case .insightHistory:
            InsightHistoryView(viewModel: makeInsightHistoryViewModel(), router: router)
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

    private func makeWeeklyReportViewModel(weekStart: Date) -> WeeklyReportViewModel {
        WeeklyReportViewModel(
            fetchWeeklyReportUseCase: dependencyContainer.fetchWeeklyReportUseCase,
            weekStart: weekStart
        )
    }

    private func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            sleepRepository: dependencyContainer.sleepRepository,
            moodRepository: dependencyContainer.moodRepository,
            calendarRepository: dependencyContainer.calendarRepository
        )
    }

    private func makeInsightHistoryViewModel() -> InsightHistoryViewModel {
        InsightHistoryViewModel(
            repository: dependencyContainer.insightRepository,
            generateInsightUseCase: dependencyContainer.generateInsightUseCase
        )
    }

    private func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            userDefaultsManager: userDefaultsManager,
            notificationService: dependencyContainer.notificationService,
            generatePredictionTextUseCase: dependencyContainer.generatePredictionTextUseCase
        )
    }

    private func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            userDefaultsManager: userDefaultsManager,
            insightRepository: dependencyContainer.insightRepository
        )
    }

    private func preferredScheme(forTheme theme: UserDefaultsManager.AppTheme) -> ColorScheme? {
        switch theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
