import Foundation
import PromiseKit

protocol WriteCourseReviewInteractorProtocol {
    func doCourseReviewLoad(request: WriteCourseReview.CourseReviewLoad.Request)
    func doCourseReviewTextUpdate(request: WriteCourseReview.CourseReviewTextUpdate.Request)
    func doCourseReviewScoreUpdate(request: WriteCourseReview.CourseReviewScoreUpdate.Request)
    func doCourseReviewMainAction(request: WriteCourseReview.CourseReviewMainAction.Request)
}

final class WriteCourseReviewInteractor: WriteCourseReviewInteractorProtocol {
    weak var moduleOutput: WriteCourseReviewOutputProtocol?

    private let presenter: WriteCourseReviewPresenterProtocol
    private let provider: WriteCourseReviewProviderProtocol

    private let courseID: Course.IdType
    private let context: Context

    private var courseReview: CourseReview?
    private var currentText: String
    private var currentScore: Int

    init(
        courseID: Course.IdType,
        courseReview: CourseReview?,
        presenter: WriteCourseReviewPresenterProtocol,
        provider: WriteCourseReviewProviderProtocol
    ) {
        self.courseID = courseID
        self.context = courseReview == nil ? .create : .update
        self.courseReview = courseReview
        self.currentText = courseReview?.text ?? ""
        self.currentScore = courseReview?.score ?? 0
        self.presenter = presenter
        self.provider = provider
    }

    func doCourseReviewLoad(request: WriteCourseReview.CourseReviewLoad.Request) {
        self.presenter.presentCourseReview(
            response: WriteCourseReview.CourseReviewLoad.Response(
                result: WriteCourseReview.CourseReviewInfo(
                    text: self.currentText,
                    score: self.currentScore
                )
            )
        )
    }

    func doCourseReviewTextUpdate(request: WriteCourseReview.CourseReviewTextUpdate.Request) {
        self.currentText = request.text

        self.presenter.presentCourseReviewTextUpdate(
            response: WriteCourseReview.CourseReviewTextUpdate.Response(
                result: WriteCourseReview.CourseReviewInfo(
                    text: self.currentText,
                    score: self.currentScore
                )
            )
        )
    }

    func doCourseReviewScoreUpdate(request: WriteCourseReview.CourseReviewScoreUpdate.Request) {
        self.currentScore = request.score

        self.presenter.presentCourseReviewScoreUpdate(
            response: WriteCourseReview.CourseReviewScoreUpdate.Response(
                result: WriteCourseReview.CourseReviewInfo(
                    text: self.currentText,
                    score: self.currentScore
                )
            )
        )
    }

    func doCourseReviewMainAction(request: WriteCourseReview.CourseReviewMainAction.Request) {
        let trimmedText = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        self.presenter.presentWaitingState(response: .init(shouldDismiss: false))

        switch self.context {
        case .create:
            self.createCourseReview(score: self.currentScore, text: trimmedText)
        case .update:
            self.updateCourseReview(self.courseReview.require(), score: self.currentScore, text: trimmedText)
        }
    }

    // MARK: - Private API

    private func createCourseReview(score: Int, text: String) {
        self.provider.create(courseID: self.courseID, score: score, text: text).done { createdCourseReview in
            self.courseReview = createdCourseReview

            self.presenter.presentCourseReviewMainActionResult(
                response: WriteCourseReview.CourseReviewMainAction.Response(isSuccessful: true)
            )
            self.moduleOutput?.handleCourseReviewCreated(createdCourseReview)
        }.catch { _ in
            self.presenter.presentCourseReviewMainActionResult(
                response: WriteCourseReview.CourseReviewMainAction.Response(isSuccessful: false)
            )
        }
    }

    private func updateCourseReview(_ courseReview: CourseReview, score: Int, text: String) {
        courseReview.score = score
        courseReview.text = text

        self.provider.update(courseReview: courseReview).done { updatedCourseReview in
            self.courseReview = updatedCourseReview

            self.presenter.presentCourseReviewMainActionResult(
                response: WriteCourseReview.CourseReviewMainAction.Response(isSuccessful: true)
            )
            self.moduleOutput?.handleCourseReviewUpdated(updatedCourseReview)
        }.catch { _ in
            self.presenter.presentCourseReviewMainActionResult(
                response: WriteCourseReview.CourseReviewMainAction.Response(isSuccessful: false)
            )
        }
    }

    // MARK: - Inner Types

    private enum Context {
        case create
        case update
    }
}
