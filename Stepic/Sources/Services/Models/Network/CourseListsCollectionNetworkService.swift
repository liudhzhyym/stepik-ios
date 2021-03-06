import Foundation
import PromiseKit

protocol CourseListsCollectionNetworkServiceProtocol: AnyObject {
    func fetch(language: ContentLanguage, page: Int) -> Promise<([CourseListModel], Meta)>
}

final class CourseListsCollectionNetworkService: CourseListsCollectionNetworkServiceProtocol {
    private let courseListsAPI: CourseListsAPI

    init(courseListsAPI: CourseListsAPI) {
        self.courseListsAPI = courseListsAPI
    }

    func fetch(language: ContentLanguage, page: Int) -> Promise<([CourseListModel], Meta)> {
        Promise { seal in
            self.courseListsAPI.retrieve(language: language, page: page).done { lists, meta in
                seal.fulfill((lists, meta))
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}
