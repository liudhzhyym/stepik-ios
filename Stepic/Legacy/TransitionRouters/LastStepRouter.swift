//
//  LastStepRouter.swift
//  Stepic
//
//  Created by Ostrenkiy on 13.10.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import PromiseKit
import SVProgressHUD

enum LastStepError: Error {
    case multipleLastSteps
}

@available(*, deprecated, message: "Legacy class, should be refactored")
final class LastStepRouter {
    static func continueLearning(
        for course: Course,
        isAdaptive: Bool? = nil,
        didJustSubscribe: Bool = false,
        using navigationController: UINavigationController,
        skipSyllabus: Bool = false,
        courseViewSource: AnalyticsEvent.CourseViewSource
    ) {
        guard course.canContinue,
              let lastStepID = course.lastStepId else {
            return
        }

        SVProgressHUD.show()

        ApiDataDownloader.lastSteps.getObjectsByIds(
            ids: [lastStepID],
            updating: course.lastStep != nil ? [course.lastStep!] : []
        ).done { newLastSteps in
            guard let newLastStep = newLastSteps.first else {
                throw LastStepError.multipleLastSteps
            }

            course.lastStep = newLastStep
            CoreDataHelper.shared.save()
        }.ensure {
            self.navigate(
                for: course,
                isAdaptive: isAdaptive,
                didJustSubscribe: didJustSubscribe,
                using: navigationController,
                skipSyllabus: skipSyllabus,
                courseViewSource: courseViewSource
            )
        }.catch { error in
            print("error while updating lastStep: \(error)")
        }
    }

    private static func navigate(
        for course: Course,
        isAdaptive: Bool?,
        didJustSubscribe: Bool,
        using navigationController: UINavigationController,
        skipSyllabus: Bool = false,
        courseViewSource: AnalyticsEvent.CourseViewSource = .unknown
    ) {
        let shouldOpenInAdaptiveMode = isAdaptive
            ?? AdaptiveStorageManager.shared.canOpenInAdaptiveMode(courseId: course.id)
        if shouldOpenInAdaptiveMode {
            guard let cardsViewController = ControllerHelper.instantiateViewController(
                identifier: "CardsSteps",
                storyboardName: "Adaptive"
            ) as? BaseCardsStepsViewController else {
                return
            }

            cardsViewController.hidesBottomBarWhenPushed = true
            cardsViewController.course = course
            cardsViewController.didJustSubscribe = didJustSubscribe
            navigationController.pushViewController(cardsViewController, animated: true)

            SVProgressHUD.showSuccess(withStatus: "")

            return
        }

        let courseInfoController = CourseInfoAssembly(
            courseID: course.id,
            initialTab: .syllabus,
            courseViewSource: courseViewSource
        ).makeModule()

        func openSyllabus() {
            SVProgressHUD.showSuccess(withStatus: "")
            navigationController.pushViewController(courseInfoController, animated: true)
            StepikAnalytics.shared.send(.continueLastStepSyllabusOpened)
            return
        }

        func checkUnitAndNavigate(for unitID: Int) {
            if let unit = Unit.getUnit(id: unitID) {
                checkSectionAndNavigate(in: unit)
            } else {
                ApiDataDownloader.units.retrieve(ids: [unitID], existing: [], refreshMode: .update, success: { units in
                    if let unit = units.first {
                        checkSectionAndNavigate(in: unit)
                    } else {
                        print("last step router: unit not found, id = \(unitID)")
                        openSyllabus()
                    }
                }, error: { err in
                    print("last step router: error while loading unit, error = \(err)")
                    openSyllabus()
                })
            }
        }

        func navigateToStep(in unit: Unit) {
            // If last step does not exist then take first step in unit
            let stepIDPromise = Promise<Int> { seal in
                if let stepID = course.lastStep?.stepId {
                    seal.fulfill(stepID)
                } else {
                    let cachedLesson = unit.lesson ?? Lesson.getLesson(unit.lessonId)
                    ApiDataDownloader.lessons.retrieve(
                        ids: [unit.lessonId],
                        existing: cachedLesson == nil ? [] : [cachedLesson!]
                    ).done { lessons in
                        if let lesson = lessons.first {
                            unit.lesson = lesson
                        }

                        if let firstStepID = lessons.first?.stepsArray.first {
                            seal.fulfill(firstStepID)
                        } else {
                            seal.reject(NSError(domain: "error", code: 100, userInfo: nil)) // meh.
                        }
                    }.catch { _ in
                        seal.reject(NSError(domain: "error", code: 100, userInfo: nil)) // meh.
                    }
                }
            }

            stepIDPromise.done { targetStepID in
                let lessonAssembly = LessonAssembly(
                    initialContext: .unit(id: unit.id),
                    startStep: .id(targetStepID)
                )

                SVProgressHUD.showSuccess(withStatus: "")

                if !skipSyllabus {
                    navigationController.pushViewController(courseInfoController, animated: false)
                }
                navigationController.pushViewController(lessonAssembly.makeModule(), animated: true)

                LocalProgressLastViewedUpdater.shared.updateView(for: course)
                StepikAnalytics.shared.send(.continueLastStepStepOpened)
            }.catch { _ in
                openSyllabus()
            }
        }

        func checkSectionAndNavigate(in unit: Unit) {
            var sectionForUpdate: Section?
            if let retrievedSections = try? Section.getSections(unit.sectionId),
               let section = retrievedSections.first {
                sectionForUpdate = section
            }

            // Always refresh section to prevent obsolete `isReachable` state
            ApiDataDownloader.sections.retrieve(
                ids: [unit.sectionId],
                existing: sectionForUpdate == nil ? [] : [sectionForUpdate!],
                refreshMode: .update,
                success: { sections in
                    if let section = sections.first {
                        unit.section = section
                        CoreDataHelper.shared.save()

                        // Check whether unit is in exam section
                        if section.isExam && section.isReachable {
                            self.presentExamAlert(presentationController: navigationController, course: course)
                        } else if section.isReachable {
                            navigateToStep(in: unit)
                        } else {
                            openSyllabus()
                        }
                    } else {
                        print("last step router: section not found, id = \(unit.sectionId)")
                        openSyllabus()
                    }
                },
                error: { err in
                    print("last step router: error while loading section, error = \(err)")

                    // Fallback: use cached section
                    guard let section = sectionForUpdate else {
                        return openSyllabus()
                    }

                    print("last step router: using cached section")
                    // Check whether unit is in exam section
                    if section.isExam && section.isReachable {
                        self.presentExamAlert(presentationController: navigationController, course: course)
                    } else if section.isReachable {
                        navigateToStep(in: unit)
                    } else {
                        openSyllabus()
                    }
                }
            )
        }

        guard let unitID = course.lastStep?.unitId else {
            // If last step does not exist then take first section and its first unit
            guard let sectionID = course.sectionsArray.first,
                  let sections = try? Section.getSections(sectionID),
                  let cachedSection = sections.first else {
                return openSyllabus()
            }

            ApiDataDownloader.sections.retrieve(ids: [sectionID], existing: [cachedSection]).done { section in
                guard let unitID = section.first?.unitsArray.first else {
                    return print("last step router: section has no units")
                }
                checkUnitAndNavigate(for: unitID)
            }.catch { _ in
                print("last step router: unable to load section when last step does not exists")
                openSyllabus()
            }

            return
        }

        checkUnitAndNavigate(for: unitID)
    }

    private static func presentExamAlert(presentationController: UIViewController, course: Course) {
        SVProgressHUD.dismiss()

        let alert = UIAlertController(
            title: NSLocalizedString("ExamTitle", comment: ""),
            message: NSLocalizedString("LastStepRouterShowExamInWeb", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Open", comment: ""),
                style: .default,
                handler: { _ in
                    let courseWebURLPath: String = {
                        if let slug = course.slug {
                            return "\(StepikApplicationsInfo.stepikURL)/course/\(slug)"
                        } else {
                            return "\(StepikApplicationsInfo.stepikURL)/\(course.id)"
                        }
                    }()

                    WebControllerManager.shared.presentWebControllerWithURLString(
                        "\(courseWebURLPath)/syllabus?from_mobile_app=true",
                        inController: presentationController,
                        withKey: .exam,
                        allowsSafari: true,
                        backButtonStyle: .close
                    )
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel,
                handler: nil
            )
        )

        presentationController.present(module: alert)
    }
}
