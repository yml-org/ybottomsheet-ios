//
//  BottomSheetController.swift
//  YBottomSheet
//
//  Created by Dev Karan on 19/01/23.
//  Copyright © 2023 Y Media Labs. All rights reserved.
//

import UIKit

/// A view controller that manages a bottom sheet.
public class BottomSheetController: UIViewController {
    // Holds the sheet content until the view is loaded
    private let content: Content
    private enum Content {
        case view(title: String, view: UIView)
        case controller(_: UIViewController)
    }

    private var shadowSize: CGSize = .zero
    private let minimumTopOffset: CGFloat = 44
    private let minimumContentHeight: CGFloat = 88
    private var topAnchor: NSLayoutConstraint?
    private var childHeightAnchor: NSLayoutConstraint?
    private var panGesture: UIPanGestureRecognizer?
    internal lazy var lastYOffset: CGFloat = {
        sheetView.frame.origin.y
    }()

    /// Minimum downward velocity beyond which we interpret a pan gesture as a downward swipe.
    public var dismissThresholdVelocity: CGFloat = 1000

    /// Priorities for various non-required constraints.
    enum Priorities {
        static let panGesture = UILayoutPriority(775)
        static let sheetContentHugging = UILayoutPriority(751)
        static let sheetCompressionResistanceLow = UILayoutPriority.defaultLow
        static let sheetCompressionResistanceHigh = UILayoutPriority(800)
    }

    /// Dimmer view.
    let dimmerView = UIView()
    /// Bottom sheet view.
    let sheetView: UIView = {
        let view = UIView()
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = .systemBackground
        view.backgroundColor = .systemBackground
        return view
    }()
    /// Bottom sheet drag indicator view.
    public private(set) var indicatorView: DragIndicatorView!
    /// Bottom sheet header view.
    public private(set) var headerView: SheetHeaderView!
    /// Holds the sheet's child content (view or view controller).
    let contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    /// Comprises the indicator view, the header view, and the content view.
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    
    /// Appearance for bottom sheet.
    public var appearance: BottomSheetController.Appearance {
        didSet {
            guard isViewLoaded else { return }
            updateViewAppearance()
        }
    }

    /// Whether the sheet is resizable or not.
    public var isResizable: Bool { appearance.indicatorAppearance != nil }

    /// Whether the sheet contains a header.
    ///
    /// This may either be because no header appearance was specified or because the child controller is a
    /// `UINavigationController` and hence already has its own `UINavigationBar` header.
    public var hasHeader: Bool {
        guard appearance.headerAppearance != nil else { return false }

        if case let .controller(childController) = content {
            return !(childController is UINavigationController)
        }

        return true
    }

    /// Initializes a bottom sheet.
    /// - Parameters:
    ///   - title: bottom sheet title.
    ///   - childView: content view.
    ///   - appearance: bottom sheet appearance. Default is `.default`.
    public required init(
        title: String,
        childView: UIView,
        appearance: BottomSheetController.Appearance = .default
    ) {
        self.content = .view(title: title, view: childView)
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    /// Initializes a bottom sheet.
    /// - Parameters:
    ///   - childController: content view controller.
    ///   - appearance: bottom sheet appearance. Default is `.default`.
    public required init(
        childController: UIViewController,
        appearance: BottomSheetController.Appearance = .default
    ) {
        self.content = .controller(childController)
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    /// :nodoc:
    internal required init?(coder: NSCoder) { nil }
    
    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()
        build()
    }
    
    /// :nodoc:
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard shadowSize != sheetView.bounds.size else { return }
        updateShadow()
        shadowSize = contentView.bounds.size
    }
    
    /// Performing the accessibility escape gesture dismisses the bottom sheet.
    public override func accessibilityPerformEscape() -> Bool {
        didDismiss()
        return true
    }
}

private extension BottomSheetController {
    func commonInit() {
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    func build() {
        switch content {
        case .view(title: let title, view: let childView):
            build(childView, title: title)
        case .controller(let childController):
            build(childController)
        }
    }

    func build(_ subview: UIView, title: String) {
        contentView.addSubview(subview)
        subview.constrainEdges()
        indicatorView = DragIndicatorView(appearance: appearance.indicatorAppearance ?? .default)
        headerView = SheetHeaderView(title: title, appearance: appearance.headerAppearance ?? .default)
        headerView.delegate = self
        buildSheet()
    }
    
    func build(_ childController: UIViewController) {
        addChild(childController)
        build(childController.view, title: childController.title ?? "")
        childController.didMove(toParent: self)
    }
    
    func buildSheet() {
        buildViews()
        buildConstraints()
        view.layoutIfNeeded()
        updateViewAppearance()
        addGestures()
    }

    func buildViews() {
        view.addSubview(dimmerView)
        view.addSubview(sheetView)
        sheetView.addSubview(stackView)
        stackView.addArrangedSubview(indicatorView)
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(contentView)
    }

    func buildConstraints() {
        dimmerView.constrainEdges()
        sheetView.constrainEdges(.notTop)

        sheetView.constrain(
            .topAnchor,
            to: view.safeAreaLayoutGuide.topAnchor,
            relatedBy: .greaterThanOrEqual,
            constant: minimumTopOffset
        )

        stackView.constrain(
            .topAnchor,
            to: sheetView.topAnchor,
            constant: appearance.layout.cornerRadius - (appearance.indicatorAppearance?.layout.size.height ?? 0)
        )
        stackView.constrainEdges(.horizontal, to: view.safeAreaLayoutGuide)
        stackView.constrainEdges(.bottom, to: view.safeAreaLayoutGuide, relatedBy: .greaterThanOrEqual)
        stackView.constrainEdges(.bottom, to: view.safeAreaLayoutGuide, priority: Priorities.sheetContentHugging)

        contentView.constrainEdges(.horizontal)
        headerView.constrainEdges(.horizontal)
    }

    func updateViewAppearance() {
        sheetView.layer.cornerRadius = appearance.layout.cornerRadius
        updateShadow()
        dimmerView.backgroundColor = appearance.dimmerColor
        updateIndicatorView()
        updateHeaderView()
        updateChildView()
        view.layoutIfNeeded()
    }
    
    func updateIndicatorView() {
        indicatorView.isHidden = !isResizable
        if let indicatorAppearance = appearance.indicatorAppearance {
            indicatorView.appearance = indicatorAppearance
            if panGesture == nil {
                let pan = UIPanGestureRecognizer()
                pan.addTarget(self, action: #selector(handlePan))
                sheetView.addGestureRecognizer(pan)
                panGesture = pan
            }
        } else {
            if let pan = panGesture {
                sheetView.removeGestureRecognizer(pan)
                panGesture = nil
            }
        }
    }

    func updateHeaderView() {
        headerView.isHidden = !hasHeader
        if let headerAppearance = appearance.headerAppearance {
            headerView.appearance = headerAppearance
        }
    }

    func updateChildView() {
        guard let childView = contentView.subviews.first else { return }

        let height: CGFloat
        let priority: UILayoutPriority

        if let minimum = appearance.minimumContentHeight {
            // If a minimum is specified, we make the sheet relatively easy to compress
            // and enforce that specified minimum.
            height = minimum
            priority = Priorities.sheetCompressionResistanceLow
        } else {
            // If no minimumContentHeight is specified, we make the sheet difficult
            // to compress beyond intrinsicContentSize.height and enforce an absolute minimum.
            height = minimumContentHeight // absolute minimum
            priority = Priorities.sheetCompressionResistanceHigh
        }

        childView.setContentCompressionResistancePriority(priority, for: .vertical)
        if let anchor = childHeightAnchor {
            anchor.constant = height
        } else {
            childHeightAnchor = childView.constrain(.heightAnchor, relatedBy: .greaterThanOrEqual, constant: height)
        }
    }
    
    func updateShadow() {
        appearance.elevation?.apply(layer: sheetView.layer)
    }
    
    func addGestures() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDown))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onDimmerTap))
        dimmerView.addGestureRecognizer(tapGesture)
    }

    func onDismiss() {
        dismiss(animated: true)
    }
}

extension BottomSheetController: SheetHeaderViewDelegate {
    @objc
    func didDismiss() {
        onDismiss()
    }
}

private extension BottomSheetController {
    @objc
    func onSwipeDown(sender: UIGestureRecognizer) {
        didDismiss()
    }
    
    @objc
    func onDimmerTap(sender: UIGestureRecognizer) {
        didDismiss()
    }

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            let translation = gesture.translation(in: sheetView)
            let offset = lastYOffset + translation.y - view.safeAreaInsets.top
            if let topAnchor = topAnchor {
                topAnchor.constant = offset
            } else {
                topAnchor = sheetView.constrain(
                    .topAnchor,
                    to: view.safeAreaLayoutGuide.topAnchor,
                    constant: offset,
                    priority: Priorities.panGesture
                )
            }
            view.layoutIfNeeded()
        case .ended:
            lastYOffset = sheetView.frame.origin.y
            let velocity = gesture.velocity(in: sheetView)
            if velocity.y > dismissThresholdVelocity {
                didDismiss()
            }
        default: break
        }
    }
}

extension BottomSheetController: UIViewControllerTransitioningDelegate {
    /// Returns the animator for presenting a bottom sheet
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomSheetPresentAnimator(sheetViewController: self)
    }
    
    /// Returns the animator for dismissing a bottom sheet
    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomSheetDismissAnimator(sheetViewController: self)
    }
}

// Methods for unit testing
internal extension BottomSheetController {
    @objc
    func simulateOnSwipeDown() {
        onSwipeDown(sender: UISwipeGestureRecognizer())
    }

    @objc
    func simulateOnDimmerTap() {
        onDimmerTap(sender: UITapGestureRecognizer())
    }

    @objc
    @discardableResult
    func simulateDragging(_ gesture: UIPanGestureRecognizer) -> Bool {
        guard isResizable else { return false }
        handlePan(gesture)
        return true
    }

    @objc
    func simulateDismiss() {
        didDismiss()
    }
}
