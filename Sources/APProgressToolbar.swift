import SnapKit
import UIKit

// MARK: - Protocol

@MainActor
public protocol APProgressToolbarDelegate: AnyObject {
    func didCancelButtonPressed(_ toolbar: APProgressToolbar)
}

// MARK: - APProgressToolbar

/// A floating progress card that slides up from the bottom of its superview.
///
/// Layout: a blurred, rounded card holding a title, a percentage, a round cancel button,
/// and a thin progress track whose fill can be a gradient. Position and size are managed by the
/// toolbar itself: add it to a superview, then call `show(_:)` / `hide(_:)`.
@MainActor
public final class APProgressToolbar: UIView {
    
    // MARK: - Layout Constants
    
    public enum Layout {
        public static let cardHeight: CGFloat = 62
        /// Horizontal inset of the card from the superview's edges.
        public static let horizontalInset: CGFloat = 14
        /// Space between the card and the superview's bottom safe area.
        public static let bottomInset: CGFloat = 6
        static let contentInsets = UIEdgeInsets(top: 12, left: 14, bottom: 14, right: 14)
        static let cancelButtonSize: CGFloat = 28
        static let trackHeight: CGFloat = 6
        static let hideDelay: Duration = .seconds(1)
    }
    
    // MARK: - Properties
    
    public weak var actionDelegate: APProgressToolbarDelegate?
    public private(set) var isShown = false
    
    public var text: String? {
        didSet { titleLabel.text = text }
    }
    
    /// Extra space to leave at the bottom, for example the height of an ad banner.
    public var extraBottomOffset: CGFloat = 0 { didSet { updateLayout() } }
    
    // MARK: - Appearance
    
    /// Card fill, drawn over a blur at 96% opacity.
    public var cardBackgroundColor: UIColor = .systemBackground { didSet { applyAppearance() } }
    public var cardBorderColor: UIColor = .separator { didSet { applyAppearance() } }
    public var titleColor: UIColor = .label { didSet { applyAppearance() } }
    public var percentColor: UIColor = .secondaryLabel { didSet { applyAppearance() } }
    public var cancelButtonBackgroundColor: UIColor = .tertiarySystemFill { didSet { applyAppearance() } }
    public var cancelButtonTintColor: UIColor = .label { didSet { applyAppearance() } }
    public var trackColor: UIColor = .tertiarySystemFill { didSet { applyAppearance() } }
    /// Left-to-right fill colors of the progress track. A single color gives a flat fill.
    public var progressColors: [UIColor] = [.systemBlue] { didSet { applyAppearance() } }
    public var titleFont: UIFont = .systemFont(ofSize: 14, weight: .semibold) { didSet { applyAppearance() } }
    public var percentFont: UIFont = .systemFont(ofSize: 13, weight: .semibold) { didSet { applyAppearance() } }
    public var cornerRadius: CGFloat = 18 { didSet { applyAppearance() } }
    
    // MARK: - UI Elements
    
    private let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let tintView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let percentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "0%"
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    lazy var stopButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        button.layer.cornerRadius = Layout.cancelButtonSize / 2
        button.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.actionDelegate?.didCancelButtonPressed(self)
        }, for: .touchUpInside)
        return button
    }()
    
    public lazy var progressBar: APProgressBar = {
        let bar = APProgressBar()
        bar.onProgressChanged = { [weak self] progress in
            self?.percentLabel.text = "\(Int((progress * 100).rounded()))%"
        }
        return bar
    }()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
    
    // MARK: - Public Methods
    
    public func show(_ animated: Bool) async {
        guard !isShown else { return }
        
        isShown = true
        stopButton.isEnabled = true
        
        guard superview != nil else { return }
        
        frame = hiddenFrame()
        isHidden = false
        
        let finalFrame = shownFrame()
        
        if !animated {
            frame = finalFrame
            return
        }
        
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, animations: {
                self.frame = finalFrame
            }, completion: { _ in
                continuation.resume()
            })
        }
    }
    
    /// Slides the card off screen. An animated hide waits `Layout.hideDelay` first so a finished
    /// progress bar stays visible briefly; a `show(_:)` during that wait cancels the hide.
    public func hide(_ animated: Bool) async {
        guard isShown else { return }
        
        isShown = false
        stopButton.isEnabled = false
        
        guard superview != nil else { return }
        
        if !animated {
            frame = hiddenFrame()
            isHidden = true
            return
        }
        
        try? await Task.sleep(for: Layout.hideDelay)
        
        // show() raced in during the delay; leave the card where it is.
        guard !isShown else { return }
        
        let finalFrame = hiddenFrame()
        
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn], animations: {
                self.frame = finalFrame
            }, completion: { _ in
                continuation.resume()
            })
        }
        
        if !isShown {
            isHidden = true
        }
    }
    
    /// Repositions the card for the superview's current size. Call after rotation or when the
    /// space below the card changes.
    public func updateLayout() {
        guard superview != nil else { return }
        frame = isShown ? shownFrame() : hiddenFrame()
    }
    
    // MARK: - Frames
    
    private func shownFrame() -> CGRect {
        guard let superview else { return .zero }
        let width = superview.bounds.width - Layout.horizontalInset * 2
        let y = superview.bounds.height - superview.safeAreaInsets.bottom - extraBottomOffset - Layout.bottomInset - Layout.cardHeight
        return CGRect(x: Layout.horizontalInset, y: y, width: width, height: Layout.cardHeight)
    }
    
    private func hiddenFrame() -> CGRect {
        guard let superview else { return .zero }
        let width = superview.bounds.width - Layout.horizontalInset * 2
        return CGRect(x: Layout.horizontalInset, y: superview.bounds.height + 20, width: width, height: Layout.cardHeight)
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 10)
        
        addSubview(cardView)
        cardView.addSubview(blurView)
        cardView.addSubview(tintView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(percentLabel)
        cardView.addSubview(stopButton)
        cardView.addSubview(progressBar)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tintView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stopButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.contentInsets.top - 4)
            make.trailing.equalToSuperview().inset(Layout.contentInsets.right)
            make.size.equalTo(Layout.cancelButtonSize)
        }
        
        percentLabel.snp.makeConstraints { make in
            make.centerY.equalTo(stopButton)
            make.trailing.equalTo(stopButton.snp.leading).offset(-12)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(stopButton)
            make.leading.equalToSuperview().offset(Layout.contentInsets.left)
            make.trailing.lessThanOrEqualTo(percentLabel.snp.leading).offset(-12)
        }
        
        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.contentInsets.left)
            make.bottom.equalToSuperview().inset(Layout.contentInsets.bottom)
            make.height.equalTo(Layout.trackHeight)
        }
        
        // CGColor-backed properties (border, shadow) don't follow dynamic colors on their own.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyAppearance()
        }
        
        applyAppearance()
    }
    
    private func applyAppearance() {
        cardView.layer.cornerRadius = cornerRadius
        cardView.layer.borderColor = cardBorderColor.resolvedColor(with: traitCollection).cgColor
        tintView.backgroundColor = cardBackgroundColor.withAlphaComponent(0.96)
        
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        percentLabel.font = percentFont
        percentLabel.textColor = percentColor
        
        stopButton.backgroundColor = cancelButtonBackgroundColor
        stopButton.tintColor = cancelButtonTintColor
        
        progressBar.trackColor = trackColor
        progressBar.fillColors = progressColors
        
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.45 : 0.18
    }
}

// MARK: - APProgressBar

/// A thin rounded track with a left-to-right (optionally gradient) fill.
@MainActor
public final class APProgressBar: UIView {
    
    /// 0...1. Values outside the range are clamped.
    public var progress: CGFloat = 0 {
        didSet {
            progress = min(max(progress, 0), 1)
            setNeedsLayout()
            onProgressChanged?(progress)
        }
    }
    
    var trackColor: UIColor = .tertiarySystemFill {
        didSet { backgroundColor = trackColor }
    }
    
    var fillColors: [UIColor] = [.systemBlue] {
        didSet { applyFillColors() }
    }
    
    /// Called whenever `progress` changes, with the clamped value.
    var onProgressChanged: ((CGFloat) -> Void)?
    
    private let fillLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = trackColor
        layer.masksToBounds = true
        layer.addSublayer(fillLayer)
        applyFillColors()
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyFillColors()
        }
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius = bounds.height / 2
        layer.cornerRadius = radius
        fillLayer.cornerRadius = radius
        
        // Keep the fill at least as wide as it is tall so the rounded end stays visible.
        let width = max(bounds.width * progress, progress > 0 ? bounds.height : 0)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        fillLayer.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
        CATransaction.commit()
    }
    
    private func applyFillColors() {
        fillLayer.colors = fillColors.map { $0.resolvedColor(with: traitCollection).cgColor }
    }
}
