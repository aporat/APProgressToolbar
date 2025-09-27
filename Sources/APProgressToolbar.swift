import GTProgressBar
import SnapKit
import UIKit

// MARK: - Protocol
public protocol APProgressToolbarDelegate: AnyObject {
    func didCancelButtonPressed(_ toolbar: APProgressToolbar)
}

// MARK: - Class
@MainActor
public final class APProgressToolbar: UIView {
    
    // MARK: - Properties
    public weak var actionDelegate: APProgressToolbarDelegate?
    public private(set) var isShown = false
    
    public var text: String? {
        didSet {
            titleLabel.text = text
        }
    }
    
    // MARK: - UI Elements
    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setImage(UIImage(named: "toolbar-stop"), for: .normal)
        
        let action = UIAction { [weak self] _ in
            guard let self = self else { return }
            self.actionDelegate?.didCancelButtonPressed(self)
        }
        button.addAction(action, for: .touchUpInside)
        return button
    }()
    
    private lazy var mainBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.75
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .clear
        return label
    }()
    
    public lazy var progressBar: GTProgressBar = {
        let bar = GTProgressBar()
        bar.displayLabel = true
        bar.font = .systemFont(ofSize: 13)
        bar.labelTextColor = .white
        bar.progressLabelInsetRight = 15
        bar.barFillInset = 1
        return bar
    }()
    
    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Lifecycle
    public override func updateConstraints() {
        super.updateConstraints()
        setupConstraints()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    public func show(_ animated: Bool) async {
        guard !isShown, let superview = superview else { return }
        
        isShown = true
        stopButton.isEnabled = true
        
        self.frame = CGRect(x: 0, y: superview.bounds.height, width: superview.bounds.width, height: 55)
        self.isHidden = false
        
        let finalFrame = CGRect(x: 0, y: superview.bounds.height - 55, width: superview.bounds.width, height: 55)
        
        if !animated {
            self.frame = finalFrame
            return
        }
        
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: 0.4, animations: {
                self.frame = finalFrame
            }, completion: { _ in
                continuation.resume()
            })
        }
    }
    
    public func hide(_ animated: Bool) async {
        guard isShown, let superview = superview else { return }
        
        isShown = false
        stopButton.isEnabled = false
        
        let finalFrame = CGRect(x: 0, y: superview.bounds.height, width: superview.bounds.width, height: 55)
        
        if !animated {
            self.frame = finalFrame
            self.isHidden = true
            return
        }
        
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: 0.4, delay: 1.0, options: [], animations: {
                self.frame = finalFrame
            }, completion: { _ in
                continuation.resume()
            })
        }
        
        self.isHidden = true
    }
    
    // MARK: - Actions
    private func didCancelButtonPressed() {
        actionDelegate?.didCancelButtonPressed(self)
    }
    
    // MARK: - Private Methods
    private func setupView() {
        addSubview(mainBackgroundView)
        addSubview(stopButton)
        addSubview(titleLabel)
        addSubview(progressBar)
        
        setNeedsUpdateConstraints()
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                await self.deviceOrientationDidChange()
            }
        }
    }
    
    private func setupConstraints() {
        mainBackgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        stopButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(25)
            make.trailing.equalToSuperview().offset(-14)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(16)
            make.centerX.equalToSuperview()
        }
        
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.height.equalTo(12)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalTo(stopButton.snp.leading).offset(-10)
        }
    }
    
    private func deviceOrientationDidChange() async {
        if isShown {
            await show(false)
        }
    }
}
