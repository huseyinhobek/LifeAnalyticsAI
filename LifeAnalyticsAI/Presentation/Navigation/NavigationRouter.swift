// MARK: - Presentation.Navigation

import Observation
import SwiftUI

enum AppRoute: Hashable {
    case home
    case moodEntry
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

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $router.selectedTab) {
                Text("Home")
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
                    Text("Home")
                case .moodEntry:
                    Text("Mood Entry")
                case let .weeklyReport(weekStart):
                    Text("Weekly Report: \(weekStart.formatted(date: .abbreviated, time: .omitted))")
                case .insightDetail:
                    Text("Insight Detail")
                case .settings:
                    Text("Settings")
                case .onboarding:
                    Text("Onboarding")
                case .insightHistory:
                    Text("Insight History")
                }
            }
            .fullScreenCover(isPresented: $router.showOnboarding) {
                Text("Onboarding")
            }
        }
    }
}
