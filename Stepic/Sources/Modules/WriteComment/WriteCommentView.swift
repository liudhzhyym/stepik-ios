import SnapKit
import UIKit

protocol WriteCommentViewDelegate: class {
    func writeCommentView(_ view: WriteCommentView, didUpdateText text: String)
}

extension WriteCommentView {
    struct Appearance {
        let backgroundColor = UIColor.white

        let textViewInsets = LayoutInsets(top: 16, left: 16, bottom: 16, right: 16)
        let textViewFont = UIFont.systemFont(ofSize: 16)
        let textViewTextColor = UIColor.mainDark
        let textViewPlaceholderColor = UIColor.mainDark.withAlphaComponent(0.4)
    }
}

final class WriteCommentView: UIView {
    let appearance: Appearance

    weak var delegate: WriteCommentViewDelegate?

    private lazy var textView: TableInputTextView = {
        let textView = TableInputTextView()
        textView.font = self.appearance.textViewFont
        textView.textColor = self.appearance.textViewTextColor
        textView.placeholderColor = self.appearance.textViewPlaceholderColor
        textView.placeholder = NSLocalizedString("WriteCommentPlaceholder", comment: "")
        textView.textInsets = .zero

        // Disable features
        textView.dataDetectorTypes = []

        textView.delegate = self

        return textView
    }()

    var isEnabled: Bool = true {
        didSet {
            self.textView.isEditable = self.isEnabled
        }
    }

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Appearance()
    ) {
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

    override func becomeFirstResponder() -> Bool {
        return self.textView.becomeFirstResponder()
    }

    func configure(viewModel: WriteCommentViewModel) {
        self.textView.text = viewModel.text
    }
}

extension WriteCommentView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.backgroundColor = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.textView)
    }

    func makeConstraints() {
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.snp.makeConstraints { make in
            make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading).offset(self.appearance.textViewInsets.left)
            make.top.equalToSuperview().offset(self.appearance.textViewInsets.top)
            make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing).offset(-self.appearance.textViewInsets.right)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-self.appearance.textViewInsets.bottom)
        }
    }
}

// MARK: - WriteCommentView: UITextViewDelegate -

extension WriteCommentView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.writeCommentView(self, didUpdateText: textView.text)
    }
}