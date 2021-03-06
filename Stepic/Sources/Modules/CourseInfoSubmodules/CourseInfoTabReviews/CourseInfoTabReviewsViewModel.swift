import Foundation

struct CourseInfoTabReviewsViewModel {
    // swiftlint:disable:next type_name
    typealias ID = Int

    let uniqueIdentifier: ID
    let userName: String
    let dateRepresentation: String
    let text: String
    let avatarImageURL: URL?
    let score: Int
    let isCurrentUserReview: Bool
}
