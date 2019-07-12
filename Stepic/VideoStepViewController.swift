//
//  VideoStepViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 14.10.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import UIKit
import MediaPlayer
import SVProgressHUD
import SnapKit

class VideoStepViewController: UIViewController {

    var video: Video!
    var step: Step!
    var stepId: Int!
    var lessonSlug: String!

    var startStepId: Int!
    var startStepBlock: (() -> Void)!
    var shouldSendViewsBlock: (() -> Bool)!

    var assignment: Assignment?

    var nextLessonHandler: (() -> Void)? {
        didSet {
            refreshNextPrevButtons()
        }
    }
    var prevLessonHandler: (() -> Void)? {
        didSet {
            refreshNextPrevButtons()
        }
    }

    var nController: UINavigationController?
    var nItem: UINavigationItem!

    //variable for sending analytics correctly - if view appears after dismissing video player, the event is not being sent
    var didPresentVideoPlayer: Bool = false

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    @IBOutlet weak var discussionCountView: DiscussionCountView!
    @IBOutlet weak var discussionCountViewHeight: NSLayoutConstraint!

    @IBOutlet weak var prevLessonButton: UIButton!
    @IBOutlet weak var nextLessonButton: UIButton!
    @IBOutlet weak var nextLessonButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var prevLessonButtonHeight: NSLayoutConstraint!

    @IBOutlet weak var prevNextLessonButtonsContainerViewHeight: NSLayoutConstraint!

    var imageTapHelper: ImageTapHelper!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(VideoStepViewController.updatedStepNotification(_:)), name: NSNotification.Name(rawValue: LessonPresenter.stepUpdatedNotification), object: nil)

        imageTapHelper = ImageTapHelper(imageView: thumbnailImageView, action: {
            [weak self]
            _ in
            self?.playVideo()
        })

        nextLessonButton.setTitle("  \(NSLocalizedString("NextLesson", comment: ""))  ", for: UIControl.State())
        prevLessonButton.setTitle("  \(NSLocalizedString("PrevLesson", comment: ""))  ", for: UIControl.State())

        initialize()
        refreshNextPrevButtons()
        navigationController?.navigationBar.sizeToFit()
    }

    @objc func sharePressed(_ item: UIBarButtonItem) {
//        AnalyticsReporter.reportEvent(AnalyticsEvents.Syllabus.shared, parameters: nil)

        guard let slug = lessonSlug, let stepid = stepId else {
            return
        }
        DispatchQueue.global(qos: .default).async {
            [weak self] in
            let shareVC = SharingHelper.getSharingController(StepicApplicationsInfo.stepicURL + "/lesson/" + slug + "/step/" + "\(stepid)")
            shareVC.popoverPresentationController?.barButtonItem = item
            DispatchQueue.main.async {
                [weak self] in
                self?.present(shareVC, animated: true, completion: nil)
            }
        }
    }

    func initialize() {
        thumbnailImageView.sd_setImage(with: URL(string: video.thumbnailURL), placeholderImage: Images.videoPlaceholder)

        if let discussionCount = step.discussionsCount {
            discussionCountView.commentsCount = discussionCount
            discussionCountView.showCommentsHandler = {
                [weak self] in
                self?.showComments()
            }
        } else {
            discussionCountViewHeight.constant = 0
        }

        nextLessonButton.setStepicWhiteStyle()
        prevLessonButton.setStepicWhiteStyle()
    }

    func refreshNextPrevButtons() {
        if nextLessonButton != nil {
            nextLessonButton.isHidden = nextLessonHandler == nil
        }
        if prevLessonButton != nil {
            prevLessonButton.isHidden = prevLessonHandler == nil
        }
    }

    @objc func updatedStepNotification(_ notification: Foundation.Notification) {
        initialize()
    }

    fileprivate func presentNoVideoAlert() {
        let alert = UIAlertController(title: NSLocalizedString("NoVideo", comment: ""), message: NSLocalizedString("AuthorDidntUploadVideo", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func playVideo() {

        if video.urls.count == 0 {
            presentNoVideoAlert()
            return
        }

        if video.state == VideoState.cached || (ConnectionHelper.shared.reachability.isReachableViaWiFi() || ConnectionHelper.shared.reachability.isReachableViaWWAN()) {
            let player = StepicVideoPlayerViewController(nibName: "StepicVideoPlayerViewController", bundle: nil)
            player.video = self.video
            self.present(player, animated: true, completion: {
                [weak self] in
                print("stepic player successfully presented!")
                self?.didPresentVideoPlayer = true
                AnalyticsReporter.reportEvent(AnalyticsEvents.VideoPlayer.opened, parameters: nil)
            })
        } else {
//            if let vc = self.parentNavigationController {
//                Messages.sharedManager.showConnectionErrorMessage(inController: vc)
//            }
        }
    }

    @IBAction func playButtonPressed(_ sender: UIButton) {
        playVideo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(VideoStepViewController.sharePressed(_:)))
        nItem.rightBarButtonItems = [shareBarButtonItem]

        if let discussionCount = step.discussionsCount {
            discussionCountView.commentsCount = discussionCount
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate func animateTabSelection() {
        //Animate the views
        if let cstep = self.step {
            if cstep.block.name == "video" {
                NotificationCenter.default.post(name: .stepDone, object: nil, userInfo: ["id": cstep.id])
                DispatchQueue.main.async {
                    cstep.progress?.isPassed = true
                    CoreDataHelper.instance.save()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        guard (step) != nil else {
            return
        }

        LocalProgressLastViewedUpdater.shared.updateView(for: step)

        if !didPresentVideoPlayer {
            AnalyticsReporter.reportEvent(AnalyticsEvents.Step.opened, parameters: ["item_name": step.block.name as NSObject])
            AmplitudeAnalyticsEvents.Steps.stepOpened(step: step.id, type: step.block.name, number: stepId - 1).send()
        } else {
            didPresentVideoPlayer = false
        }

        let stepid = step.id
        if stepId - 1 == startStepId {
            startStepBlock()
        }
        if shouldSendViewsBlock() {

            performRequest({
                [weak self] in
                print("Sending view for step with id \(stepid) & assignment \(String(describing: self?.assignment?.id))")
                _ = ApiDataDownloader.views.create(stepId: stepid, assignment: self?.assignment?.id, success: {
                    [weak self] in
                    self?.animateTabSelection()
                }, error: {
                    [weak self]
                    error in

                    switch error {
                    case .notAuthorized:
                        return
                    default:
                        self?.animateTabSelection()
                        print("initializing post views task")
                        print("user id \(String(describing: AuthInfo.shared.userId)) , token \(String(describing: AuthInfo.shared.token))")
                        if let userId = AuthInfo.shared.userId,
                           let token = AuthInfo.shared.token {

                            let task = PostViewsExecutableTask(stepId: stepid, assignmentId: self?.assignment?.id, userId: userId)
                            ExecutionQueues.sharedQueues.connectionAvailableExecutionQueue.push(task)

                            let userPersistencyManager = PersistentUserTokenRecoveryManager(baseName: "Users")
                            userPersistencyManager.writeStepicToken(token, userId: userId)

                            let taskPersistencyManager = PersistentTaskRecoveryManager(baseName: "Tasks")
                            taskPersistencyManager.writeTask(task, name: task.id)

                            let queuePersistencyManager = PersistentQueueRecoveryManager(baseName: "Queues")
                            queuePersistencyManager.writeQueue(ExecutionQueues.sharedQueues.connectionAvailableExecutionQueue, key: ExecutionQueues.sharedQueues.connectionAvailableExecutionQueueKey)
                        } else {
                            print("Could not get current user ID or token to post views")
                        }
                    }
                })
            })
        }
    }

    @IBAction func showCommentsPressed(_ sender: AnyObject) {
        showComments()
    }

    func showComments() {
        if let discussionProxyId = step.discussionProxyId {
            let assembly = DiscussionsLegacyAssembly(
                discussionProxyID: discussionProxyId,
                stepID: step.id
            )
            self.nController?.pushViewController(assembly.makeModule(), animated: true)
        } else {
            //TODO: Load comments here
        }
    }

    @IBAction func prevLessonPressed(_ sender: UIButton) {
        prevLessonHandler?()
    }

    @IBAction func nextLessonPressed(_ sender: UIButton) {
        nextLessonHandler?()
    }

    deinit {
        print("deinit VideoStepViewController")
    }
}
