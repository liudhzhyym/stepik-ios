import UIKit

final class CourseInfoAssembly: Assembly {
    private let courseID: Course.IdType
    private let initialTab: CourseInfo.Tab
    private let didJustSubscribe: Bool
    private let courseViewSource: AnalyticsEvent.CourseViewSource

    init(
        courseID: Course.IdType,
        initialTab: CourseInfo.Tab = .info,
        didJustSubscribe: Bool = false,
        courseViewSource: AnalyticsEvent.CourseViewSource
    ) {
        self.courseID = courseID
        self.initialTab = initialTab
        self.didJustSubscribe = didJustSubscribe
        self.courseViewSource = courseViewSource
    }

    func makeModule() -> UIViewController {
        let provider = CourseInfoProvider(
            courseID: self.courseID,
            coursesPersistenceService: CoursesPersistenceService(),
            coursesNetworkService: CoursesNetworkService(coursesAPI: CoursesAPI()),
            progressesPersistenceService: ProgressesPersistenceService(),
            progressesNetworkService: ProgressesNetworkService(progressesAPI: ProgressesAPI()),
            reviewSummariesPersistenceService: CourseReviewSummariesPersistenceService(),
            reviewSummariesNetworkService: CourseReviewSummariesNetworkService(
                courseReviewSummariesAPI: CourseReviewSummariesAPI()
            ),
            coursePurchasesPersistenceService: CoursePurchasesPersistenceService(),
            coursePurchasesNetworkService: CoursePurchasesNetworkService(coursePurchasesAPI: CoursePurchasesAPI()),
            userCoursesNetworkService: UserCoursesNetworkService(userCoursesAPI: UserCoursesAPI())
        )
        let presenter = CourseInfoPresenter()

        let notificationsRegistrationService = NotificationsRegistrationService(
            presenter: NotificationsRequestAlertPresenter(context: .courseSubscription),
            analytics: .init(source: .courseSubscription)
        )

        let dataBackUpdateService = DataBackUpdateService(
            unitsNetworkService: UnitsNetworkService(unitsAPI: UnitsAPI()),
            sectionsNetworkService: SectionsNetworkService(sectionsAPI: SectionsAPI()),
            coursesNetworkService: CoursesNetworkService(coursesAPI: CoursesAPI()),
            progressesNetworkService: ProgressesNetworkService(progressesAPI: ProgressesAPI())
        )

        let interactor = CourseInfoInteractor(
            courseID: self.courseID,
            presenter: presenter,
            provider: provider,
            networkReachabilityService: NetworkReachabilityService(),
            courseSubscriber: CourseSubscriber(),
            userAccountService: UserAccountService(),
            adaptiveStorageManager: AdaptiveStorageManager(),
            notificationSuggestionManager: NotificationSuggestionManager(),
            notificationsRegistrationService: notificationsRegistrationService,
            spotlightIndexingService: SpotlightIndexingService.shared,
            dataBackUpdateService: dataBackUpdateService,
            iapService: IAPService.shared,
            analytics: StepikAnalytics.shared,
            courseViewSource: self.courseViewSource
        )
        notificationsRegistrationService.delegate = interactor

        let viewController = CourseInfoViewController(
            interactor: interactor,
            availableTabs: self.getAvailableTabs(),
            initialTab: self.initialTab,
            didJustSubscribe: self.didJustSubscribe
        )
        presenter.viewController = viewController

        return viewController
    }

    private func getAvailableTabs() -> [CourseInfo.Tab] {
        let adaptiveManager = AdaptiveStorageManager()
        return adaptiveManager.canOpenInAdaptiveMode(courseId: self.courseID)
            ? [.info, .reviews]
            : [.info, .syllabus, .reviews]
    }
}
