import SnapKit
import UIKit

protocol NewCodeQuizViewDelegate: class {
    func newCodeQuizView(_ view: NewCodeQuizView, didSelectLanguage language: CodeLanguage)
    func newCodeQuizView(_ view: NewCodeQuizView, didUpdateCode code: String)
    func newCodeQuizViewDidRequestFullscreen(_ view: NewCodeQuizView)
    // TODO: Remove this after CodePlaygroundManager code suggestion presentation refactoring.
    func newCodeQuizViewDidRequestPresentationController(_ view: NewCodeQuizView) -> UIViewController?
}

extension NewCodeQuizView {
    struct Appearance {
        let codeTextViewHeight: CGFloat = 236
    }
}

final class NewCodeQuizView: UIView {
    let appearance: Appearance
    weak var delegate: NewCodeQuizViewDelegate?

    private lazy var codeDetailsView = CodeDetailsView()

    private lazy var languagePickerView: CodeLanguagePickerView = {
        let languagePickerView = CodeLanguagePickerView()
        languagePickerView.delegate = self
        return languagePickerView
    }()

    private lazy var toolbarView: CodeToolbarView = {
        let toolbarView = CodeToolbarView()
        toolbarView.onPickLanguageButtonClick = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            if strongSelf.languagePickerView.languages.isEmpty {
                strongSelf.toolbarView.toggleLanguagePickerButton()
            } else {
                strongSelf.languagePickerView.isHidden.toggle()
                strongSelf.codeEditorStackView.isHidden = !strongSelf.languagePickerView.isHidden
            }
        }
        toolbarView.onFullscreenButtonClick = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.delegate?.newCodeQuizViewDidRequestFullscreen(strongSelf)
        }
        return toolbarView
    }()

    private lazy var codeEditorView: CodeEditorView = {
        let codeEditorView = CodeEditorView()
        codeEditorView.delegate = self
        codeEditorView.isThemeAutoUpdating = true
        return codeEditorView
    }()

    private lazy var codeEditorStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [SeparatorView(), self.codeEditorView, SeparatorView()])
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var unsupportedCodeLanguageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [SeparatorView(), UnsupportedCodeLanguageView(), SeparatorView()])
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [
                self.codeDetailsView,
                self.toolbarView,
                self.codeEditorStackView,
                self.languagePickerView,
                self.unsupportedCodeLanguageStackView
            ]
        )
        stackView.axis = .vertical
        return stackView
    }()

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: NewCodeQuizViewModel) {
        switch viewModel.finalState {
        case .default, .wrong:
            self.setCodeEditorReady(true)
            self.setCodeEditorActionControlsEnabled(true)
            self.toolbarView.isLanguagePickerEnabled = viewModel.languages.count > 1
        case .correct, .evaluation:
            self.setCodeEditorReady(true)
            self.setCodeEditorActionControlsEnabled(false)
        case .noLanguage:
            self.setCodeEditorReady(false)
            self.setCodeEditorActionControlsEnabled(false)
        case .unsupportedLanguage:
            self.languagePickerView.isHidden = true
            self.toolbarView.isHidden = true
            self.codeEditorStackView.isHidden = true
            self.unsupportedCodeLanguageStackView.isHidden = false
            self.setCodeEditorActionControlsEnabled(false)
        }

        self.codeDetailsView.configure(samples: viewModel.samples, limit: viewModel.limit)
        self.languagePickerView.languages = viewModel.languages.map { $0.rawValue }.sorted()
        self.toolbarView.language = viewModel.language?.rawValue

        self.codeEditorView.language = viewModel.language
        self.codeEditorView.code = viewModel.code
        self.codeEditorView.codeTemplate = viewModel.codeTemplate
        self.codeEditorView.theme = viewModel.codeEditorTheme
        self.codeEditorView.isEditable = false
    }

    // MARK: - Private API

    private func setCodeEditorReady(_ isReady: Bool) {
        self.languagePickerView.isHidden = isReady
        self.toolbarView.isHidden = !isReady
        self.codeEditorStackView.isHidden = !isReady
        self.unsupportedCodeLanguageStackView.isHidden = true
    }

    private func setCodeEditorActionControlsEnabled(_ isEnabled: Bool) {
        self.toolbarView.isEnabled = isEnabled
        self.codeEditorView.isEditable = isEnabled
    }
}

extension NewCodeQuizView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.stackView)
    }

    func makeConstraints() {
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.codeEditorView.translatesAutoresizingMaskIntoConstraints = false
        self.codeEditorView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.codeTextViewHeight)
        }
    }
}

extension NewCodeQuizView: CodeLanguagePickerViewDelegate {
    func codeLanguagePickerView(_ view: CodeLanguagePickerView, didSelectLanguage language: String) {
        if let codeLanguage = CodeLanguage(rawValue: language) {
            self.delegate?.newCodeQuizView(self, didSelectLanguage: codeLanguage)
        }

        self.toolbarView.collapseLanguagePickerButton()
    }
}

extension NewCodeQuizView: CodeEditorViewDelegate {
    func codeEditorViewDidChange(_ codeEditorView: CodeEditorView) {
        self.delegate?.newCodeQuizView(self, didUpdateCode: codeEditorView.code ?? "")
    }

    func codeEditorViewDidRequestSuggestionPresentationController(
        _ codeEditorView: CodeEditorView
    ) -> UIViewController? {
        return self.delegate?.newCodeQuizViewDidRequestPresentationController(self)
    }

    func codeEditorView(_ codeEditorView: CodeEditorView, beginEditing editing: Bool) {
        if self.toolbarView.isEnabled {
            self.delegate?.newCodeQuizViewDidRequestFullscreen(self)
        }
    }
}