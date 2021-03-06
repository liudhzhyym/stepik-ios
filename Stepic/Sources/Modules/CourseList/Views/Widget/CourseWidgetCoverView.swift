import SnapKit
import UIKit

extension CourseWidgetCoverView {
    class Appearance {
        let cornerRadius: CGFloat = 10

        let adaptiveMarkTextColor = UIColor.stepikAccentFixed
        let adaptiveMarkBackgroundColor = UIColor(hex6: 0xEBF2FF)
        let adaptiveMarkFont = UIFont.systemFont(ofSize: 7.0, weight: .bold)
        let adaptiveMarkHeight: CGFloat = 16.0
        let adaptiveMarkInsets = UIEdgeInsets(top: 0.0, left: 6.0, bottom: 6.0, right: 6.0)
        let adaptiveMarkLabelInsets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
        let adaptiveMarkCornerRadius: CGFloat = 8.0
        let adaptiveMarkLabelText = NSLocalizedString("WidgetAdaptiveLabel", comment: "")
    }
}

final class CourseWidgetCoverView: UIView {
    let appearance: Appearance

    private lazy var coverImageView = CourseCoverImageView()

    private lazy var adaptiveMarkLabel: UILabel = {
        let label = PaddingLabel(padding: self.appearance.adaptiveMarkLabelInsets)

        label.text = self.appearance.adaptiveMarkLabelText
        label.textAlignment = .center

        label.clipsToBounds = true
        label.layer.cornerRadius = self.appearance.adaptiveMarkCornerRadius

        label.textColor = self.appearance.adaptiveMarkTextColor
        label.backgroundColor = self.appearance.adaptiveMarkBackgroundColor
        label.font = self.appearance.adaptiveMarkFont
        return label
    }()

    var coverImageURL: URL? {
        didSet {
            self.coverImageView.loadImage(url: self.coverImageURL)
        }
    }

    var shouldShowAdaptiveMark: Bool = false {
        didSet {
            self.adaptiveMarkLabel.isHidden = !self.shouldShowAdaptiveMark
        }
    }

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
}

extension CourseWidgetCoverView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.coverImageView)
        self.addSubview(self.adaptiveMarkLabel)
    }

    func setupView() {
        self.layer.cornerRadius = self.appearance.cornerRadius
        self.clipsToBounds = true

        self.shouldShowAdaptiveMark = false
    }

    func makeConstraints() {
        self.coverImageView.translatesAutoresizingMaskIntoConstraints = false
        self.coverImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.adaptiveMarkLabel.translatesAutoresizingMaskIntoConstraints = false
        self.adaptiveMarkLabel.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.adaptiveMarkHeight)

            make.centerX.equalToSuperview()
            make.leading
                .greaterThanOrEqualToSuperview()
                .offset(self.appearance.adaptiveMarkInsets.left)
            make.trailing
                .lessThanOrEqualToSuperview()
                .offset(-self.appearance.adaptiveMarkInsets.right)
            make.bottom
                .equalToSuperview()
                .offset(-self.appearance.adaptiveMarkInsets.bottom)
        }
    }
}
