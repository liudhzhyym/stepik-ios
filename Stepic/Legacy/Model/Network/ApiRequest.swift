//
//  ApiRequest.swift
//  Stepic
//
//  Created by Alexander Karpov on 29.08.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit

enum PerformRequestError: Error {
    case noAccessToRefreshToken, other, badConnection
}

func checkToken() -> Promise<()> {
    Promise { seal in
        ApiRequestPerformer.performAPIRequest({
            seal.fulfill(())
        }, error: { error in
            seal.reject(error)
        })
    }
}

// Should preferably be called from a UIViewController subclass
func performRequest(_ request: @escaping () -> Void, error: ((PerformRequestError) -> Void)? = nil) {
    ApiRequestPerformer.performAPIRequest(request, error: error)
}

final class ApiRequestPerformer {
    static let semaphore = DispatchSemaphore(value: 1)
    static let queue = DispatchQueue(label: "perform_request_queue", qos: DispatchQoS.userInitiated)

    static func performAPIRequest(
        _ completion: @escaping () -> Void,
        error errorHandler: ((PerformRequestError) -> Void)? = nil
    ) {
        let completionWithSemaphore: () -> Void = {
            print("finished performing API Request")
            semaphore.signal()
            DispatchQueue.main.async {
                completion()
            }
        }

        let errorHandlerWithSemaphore: (PerformRequestError) -> Void = { error in
            print("finished performing API Request")
            semaphore.signal()
            DispatchQueue.main.async {
                errorHandler?(error)
            }
        }

        queue.async {
            semaphore.wait()
            print("performing API request")
            if !AuthInfo.shared.hasUser {
                print("no user in AuthInfo, retrieving")
                ApiDataDownloader.stepics.retrieveCurrentUser(
                    success: { user in
                        AuthInfo.shared.user = user
                        User.removeAllExcept(user)
                        print("retrieved current user")
                        performRequestWithAuthorizationCheck(completionWithSemaphore, error: errorHandlerWithSemaphore)
                    },
                    error: { error in
                        if let typedError = error as? URLError {
                            switch typedError.code {
                            case .notConnectedToInternet:
                                errorHandlerWithSemaphore(.badConnection)
                            default:
                                errorHandlerWithSemaphore(.other)
                            }
                        } else {
                            errorHandlerWithSemaphore(.other)
                        }
                    }
                )
            } else {
                performRequestWithAuthorizationCheck(completionWithSemaphore, error: errorHandlerWithSemaphore)
            }
        }
    }

    private static func performRequestWithAuthorizationCheck(
        _ completion: @escaping () -> Void,
        error errorHandler: ((PerformRequestError) -> Void)? = nil
    ) {
        if !AuthInfo.shared.isAuthorized && StepikSession.needsRefresh {
            _ = StepikSession.refresh(
                completion: {
                    completion()
                },
                error: { _ in
                    errorHandler?(.other)
                }
            )
            return
        }

        if AuthInfo.shared.isAuthorized && AuthInfo.shared.needsToRefreshToken {
            if let refreshToken = AuthInfo.shared.token?.refreshToken {
                ApiDataDownloader.auth.refreshTokenWith(
                    refreshToken,
                    success: { token in
                        AuthInfo.shared.token = token
                        completion()
                    },
                    failure: { error in
                        print("error while auto refresh token")
                        if error == TokenRefreshError.noAccess {
                            errorHandler?(.noAccessToRefreshToken)
                        } else {
                            errorHandler?(.other)
                        }
                    }
                )
                return
            } else {
                // No token to refresh with authorized user
                errorHandler?(.other)
                return
            }
        }

        completion()
    }
}
