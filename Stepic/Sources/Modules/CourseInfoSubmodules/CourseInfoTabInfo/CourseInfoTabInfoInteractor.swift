import Foundation
import PromiseKit

protocol CourseInfoTabInfoInteractorProtocol {
    func doCourseInfoRefresh(request: CourseInfoTabInfo.InfoLoad.Request)
}

final class CourseInfoTabInfoInteractor: CourseInfoTabInfoInteractorProtocol {
    private let presenter: CourseInfoTabInfoPresenterProtocol
    private let provider: CourseInfoTabInfoProviderProtocol
    private let analytics: Analytics

    private var course: Course?
    private var courseViewSource: AnalyticsEvent.CourseViewSource?

    private var shouldOpenedAnalyticsEventSend: Bool = true

    init(
        presenter: CourseInfoTabInfoPresenterProtocol,
        provider: CourseInfoTabInfoProviderProtocol,
        analytics: Analytics
    ) {
        self.presenter = presenter
        self.provider = provider
        self.analytics = analytics
    }

    // MARK: Get course info

    func doCourseInfoRefresh(request: CourseInfoTabInfo.InfoLoad.Request) {
        guard let course = self.course else {
            return
        }

        // Firstly present cached course info, then present remote course info only on success response.
        self.presenter.presentCourseInfo(
            response: .init(
                course: self.course,
                streamVideoQuality: self.provider.globalStreamVideoQuality
            )
        )

        self.provider.fetchUsersForCourse(course).done { course in
            self.course = course
            self.presenter.presentCourseInfo(
                response: .init(
                    course: self.course,
                    streamVideoQuality: self.provider.globalStreamVideoQuality
                )
            )
        }.catch { error in
            print("Failed get course info with error: \(error)")
        }
    }
}

// MARK: - CourseInfoTabInfoInteractor: CourseInfoTabInfoInputProtocol -

extension CourseInfoTabInfoInteractor: CourseInfoTabInfoInputProtocol {
    func handleControllerAppearance() {
        if let course = self.course,
           let courseViewSource = self.courseViewSource {
            self.analytics.send(.coursePreviewScreenOpened(course: course, viewSource: courseViewSource))
            self.shouldOpenedAnalyticsEventSend = false
        } else {
            self.shouldOpenedAnalyticsEventSend = true
        }
    }

    func update(with course: Course, viewSource: AnalyticsEvent.CourseViewSource, isOnline: Bool) {
        self.course = course
        self.courseViewSource = viewSource
        self.doCourseInfoRefresh(request: .init())

        if self.shouldOpenedAnalyticsEventSend {
            self.analytics.send(.coursePreviewScreenOpened(course: course, viewSource: viewSource))
            self.shouldOpenedAnalyticsEventSend = false
        }
    }
}
