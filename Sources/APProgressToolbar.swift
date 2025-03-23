import GTProgressBar
import SnapKit
import UIKit

public protocol APProgressToolbarDelegate: AnyObject {
    func didCancelButtonPressed(_ toolbar: APProgressToolbar)
}

public final class APProgressToolbar: UIView {
    fileprivate var didSetupConstraints = false
    fileprivate let orientationDidChange = UIDevice.orientationDidChangeNotification

    public weak var actionDelegate: APProgressToolbarDelegate?
    public var isShown = false

    public var text: String? {
        didSet {
            titleLabel.text = text
        }
    }

    // MARK: - UI Elements

    fileprivate lazy var stopButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setImage(UIImage(named: "toolbar-stop"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didCancelButtonPressed(_:)), for: .touchUpInside)
        return button
    }()

    // MARK: - UI Elements

    fileprivate lazy var mainBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.75

        return view
    }()

    fileprivate lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.textColor = .white
        view.textAlignment = .center
        view.backgroundColor = .clear

        return view
    }()

    public lazy var progressBar: GTProgressBar = {
        let view = GTProgressBar()
        view.displayLabel = true
        view.font = UIFont.systemFont(ofSize: 13)
        view.labelTextColor = .white
        view.progressLabelInsetRight = 15
        view.barFillInset = 1

        return view
    }()

    // MARK: - UIView

    override required init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public func updateConstraints() {
        super.updateConstraints()

        if !didSetupConstraints {
            mainBackgroundView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }

            stopButton.snp.makeConstraints { make in
                make.centerY.equalTo(self)
                make.size.equalTo(25)
                make.trailing.equalTo(self).offset(-14)
            }

            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(self).offset(5)
                make.height.equalTo(16)
                make.centerX.equalTo(self)
            }

            progressBar.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(2)
                make.height.equalTo(12)
                make.leading.equalTo(self).offset(14)
                make.trailing.equalTo(stopButton.snp.leading).offset(-10)
            }

            didSetupConstraints = true
        }
    }

    fileprivate func setupSubviews() {
        NotificationCenter.default.addObserver(self, selector: #selector(setupPosition), name: orientationDidChange, object: nil)

        addSubview(mainBackgroundView)
        addSubview(stopButton)
        addSubview(titleLabel)
        addSubview(progressBar)

        setNeedsUpdateConstraints()
    }

    @objc fileprivate func setupPosition() {
        if isShown {
            hide(false) {
                self.isHidden = false
                self.show(false)
            }
        } else {
            setNeedsLayout()
        }
    }

    public func show(_ animated: Bool, completion: (() -> Void)? = nil) {
        if !isShown {
            isShown = true

            stopButton.isEnabled = true

            if let superview = self.superview {
                frame = CGRect(x: 0, y: superview.bounds.size.height, width: superview.bounds.size.width, height: 55)
            }

            if animated {
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    if let superview = self.superview {
                        self.frame = CGRect(x: 0, y: superview.bounds.size.height - 55, width: superview.bounds.size.width, height: 55)
                    }
                }) { _ in
                    self.isHidden = false
                    completion?()
                }
            } else {
                if let superview = self.superview {
                    frame = CGRect(x: 0, y: superview.bounds.size.height - 55, width: superview.bounds.size.width, height: 55)
                    isHidden = false
                    completion?()
                }
            }
        } else {
            completion?()
        }
    }

    public func hide(_ animated: Bool, completion: (() -> Void)? = nil) {
        if isShown {
            isShown = false

            stopButton.isEnabled = false

            if animated {
                UIView.animate(withDuration: 0.4, delay: 1.0, options: [], animations: {
                    if let superview = self.superview {
                        self.frame = CGRect(x: 0, y: superview.bounds.size.height, width: superview.bounds.size.width, height: 55)
                    }
                }) { _ in
                    self.isHidden = true
                    completion?()
                }
            } else {
                if let superview = self.superview {
                    frame = CGRect(x: 0, y: superview.bounds.size.height, width: superview.bounds.size.width, height: 55)
                    isHidden = true
                    completion?()
                }
            }
        } else {
            completion?()
        }
    }

    @objc public func didCancelButtonPressed(_: Any?) {
        actionDelegate?.didCancelButtonPressed(self)
    }
}
