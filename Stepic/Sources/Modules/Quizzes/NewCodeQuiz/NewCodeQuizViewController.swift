import UIKit

protocol NewCodeQuizViewControllerProtocol: AnyObject {
    func displayReply(viewModel: NewCodeQuiz.ReplyLoad.ViewModel)
    func displayFullscreen(viewModel: NewCodeQuiz.FullscreenPresentation.ViewModel)
}

final class NewCodeQuizViewController: UIViewController {
    private let interactor: NewCodeQuizInteractorProtocol

    lazy var newCodeQuizView = self.view as? NewCodeQuizView

    init(interactor: NewCodeQuizInteractorProtocol) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = NewCodeQuizView(frame: UIScreen.main.bounds)
        view.delegate = self
        self.view = view
    }
}

extension NewCodeQuizViewController: NewCodeQuizViewControllerProtocol {
    func displayReply(viewModel: NewCodeQuiz.ReplyLoad.ViewModel) {
        self.newCodeQuizView?.configure(viewModel: viewModel.data)
    }

    func displayFullscreen(viewModel: NewCodeQuiz.FullscreenPresentation.ViewModel) {
        let assembly = NewCodeQuizFullscreenAssembly(
            codeDetails: viewModel.codeDetails,
            language: viewModel.language,
            output: self
        )

        let viewController = assembly.makeModule()
        viewController.title = viewModel.lessonTitle

        self.present(moduleStack: [viewController], modalPresentationStyle: .fullScreen)
    }
}

extension NewCodeQuizViewController: NewCodeQuizViewDelegate {
    func newCodeQuizView(_ view: NewCodeQuizView, didSelectLanguage language: CodeLanguage) {
        self.interactor.doLanguageSelect(request: .init(language: language))
    }

    func newCodeQuizView(_ view: NewCodeQuizView, didUpdateCode code: String) {
        self.interactor.doReplyUpdate(request: .init(code: code))
    }

    func newCodeQuizViewDidRequestFullscreen(_ view: NewCodeQuizView) {
        self.interactor.doFullscreenAction(request: .init())
    }

    func newCodeQuizViewDidRequestPresentationController(_ view: NewCodeQuizView) -> UIViewController? { self }
}

extension NewCodeQuizViewController: NewCodeQuizFullscreenOutputProtocol {
    func update(code: String) {
        self.interactor.doReplyUpdate(request: .init(code: code))
        self.interactor.doReplyLoad(request: .init())
    }

    func submit(reply: Reply) {
        self.interactor.doReplySubmit(request: .init(reply: reply))
    }
}
