//
//  PulleyViewController.swift
//  Pulley
//
//  Created by Brendan Lee on 7/6/16.
//  Copyright © 2016 52inc. All rights reserved.
//

import UIKit

// swiftlint:disable for_where valid_ibinspectable

/**
 *  The base delegate protocol for Pulley delegates.
 */
@objc public protocol PulleyDelegate: class {

    /** This is called after size changes, so if you care about the bottomSafeArea property for custom UI layout, you can use this value.
     * NOTE: It's not called *during* the transition between sizes (such as in an animation coordinator), but rather after the resize is complete.
     */
    @objc optional func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat)

    /**
     *  Make UI adjustments for when Pulley goes to 'fullscreen'. Bottom safe area is provided for your convenience.
     */
    @objc optional func makeUIAdjustmentsForFullscreen(progress: CGFloat, bottomSafeArea: CGFloat)

    /**
     *  Make UI adjustments for changes in the drawer's distance-to-bottom. Bottom safe area is provided for your convenience.
     */
    @objc optional func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat)

    /**
     *  Called when the current drawer display mode changes (leftSide vs bottomDrawer). Make UI changes to account for this here.
     */
    @objc optional func drawerDisplayModeDidChange(drawer: PulleyViewController)
}

/**
 *  View controllers in the drawer can implement this to receive changes in state or provide values for the different drawer positions.
 */
@objc public protocol PulleyDrawerViewControllerDelegate: PulleyDelegate {

    /**
     *  Provide the collapsed drawer height for Pulley. Pulley does NOT automatically handle safe areas for you, however: bottom safe area is provided for your convenience in computing a value to return.
     */
    @objc optional func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat

    /**
     *  Provide the partialReveal drawer height for Pulley. Pulley does NOT automatically handle safe areas for you, however: bottom safe area is provided for your convenience in computing a value to return.
     */
    @objc optional func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat

    /**
     *  Return the support drawer positions for your drawer.
     */
    @objc optional func supportedDrawerPositions() -> [PulleyPosition]
}

/**
 *  View controllers that are the main content can implement this to receive changes in state.
 */
@objc public protocol PulleyPrimaryContentControllerDelegate: PulleyDelegate {

    // Not currently used for anything, but it's here for parity with the hopes that it'll one day be used.
}

/**
 *  A completion block used for animation callbacks.
 */
public typealias PulleyAnimationCompletionBlock = ((_ finished: Bool) -> Void)

/**
 Represents a Pulley drawer position.

 - collapsed:         When the drawer is in its smallest form, at the bottom of the screen.
 - partiallyRevealed: When the drawer is partially revealed.
 - open:              When the drawer is fully open.
 - closed:            When the drawer is off-screen at the bottom of the view. Note: Users cannot close or reopen the drawer on their own. You must set this programatically
 */
@objc public class PulleyPosition: NSObject {

    public static let collapsed = PulleyPosition(rawValue: 0)
    public static let partiallyRevealed = PulleyPosition(rawValue: 1)
    public static let open = PulleyPosition(rawValue: 2)
    public static let closed = PulleyPosition(rawValue: 3)

    public static let all: [PulleyPosition] = [
        .collapsed,
        .partiallyRevealed,
        .open,
        .closed
    ]

    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static func positionFor(string: String?) -> PulleyPosition {

        guard let positionString = string?.lowercased() else {

            return .collapsed
        }

        switch positionString {

        case "collapsed":
            return .collapsed

        case "partiallyrevealed":
            return .partiallyRevealed

        case "open":
            return .open

        case "closed":
            return .closed

        default:
            print("PulleyViewController: Position for string '\(positionString)' not found. Available values are: collapsed, partiallyRevealed, open, and closed. Defaulting to collapsed.")
            return .collapsed
        }
    }
}

/// Represents the current display mode for Pulley
///
/// - leftSide: Show as a floating panel on the left
/// - bottomDrawer: Show as a bottom drawer
/// - automatic: Determine it based on device / orientation / size class (like Maps.app)
public enum PulleyDisplayMode {
    case leftSide
    case bottomDrawer
    case automatic
}

/// Represents the 'snap' mode for Pulley. The default is 'nearest position'. You can use 'nearestPositionUnlessExceeded' to make the drawer feel lighter or heavier.
///
/// - nearestPosition: Snap to the nearest position when scroll stops
/// - nearestPositionUnlessExceeded: Snap to the nearest position when scroll stops, unless the distance is greater than 'threshold', in which case advance to the next drawer position.
public enum PulleySnapMode {
    case nearestPosition
    case nearestPositionUnlessExceeded(threshold: CGFloat)
}

public final class PulleyViewController: UIViewController, PulleyDrawerViewControllerDelegate {

    // MARK: - Interface Builder Outlets

    /// When using with Interface Builder only! Connect a containing view to this outlet.
    @IBOutlet public var primaryContentContainerView: UIView!

    /// When using with Interface Builder only! Connect a containing view to this outlet.
    @IBOutlet public var drawerContentContainerView: UIView!

    // MARK: - Internal Views, Recognizers, and State

    // Internal
    fileprivate let primaryContentContainer = UIView()
    fileprivate let drawerContentContainer = UIView()
    fileprivate let drawerShadowView = UIView()
    fileprivate let drawerScrollView: PulleyPassthroughScrollView = PulleyPassthroughScrollView()
    fileprivate let backgroundDimmingView = UIView()

    fileprivate var dimmingViewTapRecognizer: UITapGestureRecognizer?

    fileprivate var lastDragTargetContentOffset: CGPoint = CGPoint.zero

    // MARK: - Margins and Sizes

    public let bounceOverflowMargin: CGFloat = 20.0

    public var defaultCollapsedHeight: CGFloat = 68.0
    private var collapsedHeight: CGFloat {
        return drawerContentDelegate?.collapsedDrawerHeight?(bottomSafeArea: bottomSafeSpace) ?? defaultCollapsedHeight
    }

    public var defaultPartialRevealHeight: CGFloat = 264.0
    private var partialRevealHeight: CGFloat {
        return drawerContentDelegate?.partialRevealDrawerHeight?(bottomSafeArea: bottomSafeSpace) ?? defaultPartialRevealHeight
    }

    /// Get the current bottom safe area for Pulley. This is a convenience accessor. Most delegate methods where you'd need it will deliver it as a parameter.
    public var bottomSafeSpace: CGFloat {
        return pulleySafeAreaInsets.bottom
    }

    // The visible height of the drawer. Useful for adjusting the display of content in the main content view.
    public var visibleDrawerHeight: CGFloat {
        if drawerPosition == .closed {
            return 0.0
        }
        else {
            return drawerScrollView.bounds.height
        }
    }

    /// The inset from the top safe area when fully open. NOTE: When in 'leftSide' displayMode this is the distance to the bottom of the screen.
    @IBInspectable public var topInset: CGFloat = 20.0 {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }
        }
    }

    /// When in 'leftSide' displayMode, this is used to calculate the left inset from the edge of the screen.
    @IBInspectable public var panelInsetLeft: CGFloat = 10.0 {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }
        }
    }

    /// When in 'leftSide' displayMode, this is used to calculate the top inset from the edge of the screen.
    @IBInspectable public var panelInsetTop: CGFloat = 30.0 {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }
        }
    }

    /// The width of the panel in leftSide displayMode
    @IBInspectable public var panelWidth: CGFloat = 325.0 {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }
        }
    }

    // MARK: - Child Controllers and Delegate

    /// The current content view controller (shown behind the drawer).
    public fileprivate(set) var primaryContentViewController: UIViewController! {
        willSet {
            guard let controller = primaryContentViewController else {
                return
            }

            controller.willMove(toParentViewController: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParentViewController()
        }

        didSet {
            guard let controller = primaryContentViewController else {
                return
            }

            addChildViewController(controller)

            primaryContentContainer.addSubview(controller.view)

            controller.view.constrainToParent()

            controller.didMove(toParentViewController: self)

            if isViewLoaded {
                view.setNeedsLayout()
                setNeedsSupportedDrawerPositionsUpdate()
            }
        }
    }

    /// The current drawer view controller (shown in the drawer).
    public fileprivate(set) var drawerContentViewController: UIViewController! {
        willSet {
            guard let controller = drawerContentViewController else {
                return
            }

            controller.willMove(toParentViewController: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParentViewController()
        }

        didSet {
            guard let controller = drawerContentViewController else {
                return
            }

            addChildViewController(controller)

            drawerContentContainer.addSubview(controller.view)

            controller.view.constrainToParent()

            controller.didMove(toParentViewController: self)

            if isViewLoaded {
                view.setNeedsLayout()
                setNeedsSupportedDrawerPositionsUpdate()
            }
        }
    }

    /// The background visual effect layer for the drawer. By default this is the extraLight effect. You can change this if you want, or assign nil to remove it.
    public var drawerBackgroundVisualEffectView: UIVisualEffectView? = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight)) {
        willSet {
            drawerBackgroundVisualEffectView?.removeFromSuperview()
        }
        didSet {
            if
                let drawerBackgroundVisualEffectView = drawerBackgroundVisualEffectView,
                isViewLoaded {

                drawerScrollView.insertSubview(drawerBackgroundVisualEffectView, aboveSubview: drawerShadowView)
                drawerBackgroundVisualEffectView.clipsToBounds = true
                drawerBackgroundVisualEffectView.layer.cornerRadius = drawerCornerRadius
                view.setNeedsLayout()
            }
        }
    }

    /// The content view controller and drawer controller can receive delegate events already. This lets another object observe the changes, if needed.
    public weak var delegate: PulleyDelegate?

    // MARK: - Drawer Visual Customization

    /// The corner radius for the drawer.
    @IBInspectable public var drawerCornerRadius: CGFloat = 13.0 {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
                drawerBackgroundVisualEffectView?.layer.cornerRadius = drawerCornerRadius
            }
        }
    }

    /// The opacity of the drawer shadow.
    @IBInspectable public var shadowOpacity: Float = 0.1 {
        didSet {
            if isViewLoaded {
                drawerShadowView.layer.shadowOpacity = shadowOpacity
                view.setNeedsLayout()
            }
        }
    }

    /// The radius of the drawer shadow.
    @IBInspectable public var shadowRadius: CGFloat = 3.0 {
        didSet {
            if isViewLoaded {
                drawerShadowView.layer.shadowRadius = shadowRadius
                view.setNeedsLayout()
            }
        }
    }

    /// The opaque color of the background dimming view.
    @IBInspectable public var backgroundDimmingColor: UIColor = UIColor.black {
        didSet {
            if self.isViewLoaded {
                backgroundDimmingView.backgroundColor = backgroundDimmingColor
            }
        }
    }

    /// The maximum amount of opacity when dimming.
    @IBInspectable public var backgroundDimmingOpacity: CGFloat = 0.5 {
        didSet {
            if isViewLoaded {
                scrollViewDidScroll(drawerScrollView)
            }
        }
    }

    // MARK: - Content Touches

    /// The drawer scrollview's delaysContentTouches setting
    @IBInspectable public var delaysContentTouches: Bool = true {
        didSet {
            if isViewLoaded {
                drawerScrollView.delaysContentTouches = delaysContentTouches
            }
        }
    }

    /// The drawer scrollview's canCancelContentTouches setting
    @IBInspectable public var canCancelContentTouches: Bool = true {
        didSet {
            if isViewLoaded {
                drawerScrollView.canCancelContentTouches = canCancelContentTouches
            }
        }
    }

    // MARK: - Animation Properties

    /// The animation duration for setting the drawer position
    @IBInspectable public var animationDuration: TimeInterval = 0.3

    /// The animation delay for setting the drawer position
    @IBInspectable public var animationDelay: TimeInterval = 0.0

    /// The spring damping for setting the drawer position
    @IBInspectable public var animationSpringDamping: CGFloat = 0.75

    /// The spring's initial velocity for setting the drawer position
    @IBInspectable public var animationSpringInitialVelocity: CGFloat = 0.0

    /// This setting allows you to enable/disable Pulley automatically insetting the drawer on the left/right when in 'bottomDrawer' display mode in a horizontal orientation on a device with a 'notch' or other left/right obscurement.
    @IBInspectable public var adjustDrawerHorizontalInsetToSafeArea: Bool = true {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }
        }
    }

    // MARK: - Drawer Properties

    /// The current position of the drawer.
    public fileprivate(set) var drawerPosition: PulleyPosition = .collapsed {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// The starting position for the drawer when it first loads
    public var initialDrawerPosition: PulleyPosition = .collapsed

    /// The display mode for Pulley. Default is 'bottomDrawer', which preserves the previous behavior of Pulley. If you want it to adapt automatically, choose 'automatic'. The current display mode is available by using the 'currentDisplayMode' property.
    public var displayMode: PulleyDisplayMode = .bottomDrawer {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }
        }
    }

    /// This is here exclusively to support IBInspectable in Interface Builder because Interface Builder can't deal with enums. If you're doing this in code use the -initialDrawerPosition property instead. Available strings are: open, closed, partiallyRevealed, collapsed
    @IBInspectable public var initialDrawerPositionFromIB: String? {
        didSet {
            initialDrawerPosition = PulleyPosition.positionFor(string: initialDrawerPositionFromIB)
        }
    }

    /// Whether the drawer's position can be changed by the user. If set to `false`, the only way to move the drawer is programmatically. Defaults to `true`.
    @IBInspectable public var allowsUserDrawerPositionChange: Bool = true {
        didSet {
            enforceCanScrollDrawer()
        }
    }

    /// The animation options for setting the drawer position
    public var animationOptions: UIViewAnimationOptions = [.curveEaseInOut]

    /// The drawer snap mode
    public var snapMode: PulleySnapMode = .nearestPositionUnlessExceeded(threshold: 20.0)

    /// The drawer positions supported by the drawer
    fileprivate var supportedPositions: [PulleyPosition] = PulleyPosition.all {
        didSet {
            guard isViewLoaded else {
                return
            }

            guard supportedPositions.count > 0 else {
                supportedPositions = PulleyPosition.all
                return
            }

            view.setNeedsLayout()

            if supportedPositions.contains(drawerPosition) {
                setDrawerPosition(position: drawerPosition, animated: true)
            }
            else {
                let lowestDrawerState: PulleyPosition = supportedPositions
                        .filter { $0 != .closed }
                        .min { $0.rawValue < $1.rawValue } ?? .collapsed

                setDrawerPosition(position: lowestDrawerState, animated: false)
            }

            enforceCanScrollDrawer()
        }
    }

    fileprivate var isAnimatingDrawerPosition: Bool = false

    /// The height of the open position for the drawer
    private var heightOfOpenDrawer: CGFloat {
        let safeAreaTopInset: CGFloat

        // abxoxo
        if #available(iOS 11.0, *) {
            safeAreaTopInset = view.safeAreaInsets.top
        }
        else {
            safeAreaTopInset = 20.0
        }

        return view.bounds.height - topInset - safeAreaTopInset
    }

    // MARK: - Display Mode

    /// The currently rendered display mode for Pulley. This will match displayMode unless you have it set to 'automatic'. This will provide the 'actual' display mode (never automatic).
    public fileprivate(set) var currentDisplayMode: PulleyDisplayMode = .automatic {
        didSet {
            if isViewLoaded {
                view.setNeedsLayout()
            }

            if oldValue != currentDisplayMode {
                callDelegateDrawerDisplayModeDidChange()
            }
        }
    }

    private var displayModeForCurrentLayout: PulleyDisplayMode {
        if displayMode != .automatic {
            return displayMode
        }
        else if view.bounds.width >= 600.0 || traitCollection.horizontalSizeClass == .regular {
            return .leftSide
        }
        else {
            return .bottomDrawer
        }
    }

    // MARK: - Init

    /// Initialize the drawer controller programmtically.
    ///
    /// - Parameters:
    ///   - contentViewController: The content view controller. This view controller is shown behind the drawer.
    ///   - drawerViewController: The view controller to display inside the drawer.
    ///
    /// - Note: The drawer VC is 20pts too tall in order to have some extra space for the bounce animation. Make sure your constraints / content layout take this into account.
    ///
    required public init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)

        ({
            self.primaryContentViewController = contentViewController
            self.drawerContentViewController = drawerViewController
        })()
    }

    /// Initialize the drawer controller from Interface Builder.
    ///
    /// - Parameter aDecoder: The NSCoder to decode from.
    ///
    /// - Note: Usage notes: Make 2 container views in Interface Builder and connect their outlets to -primaryContentContainerView and -drawerContentContainerView. Then use embed segues to place your content/drawer view controllers into the appropriate container.
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Feedback Generator

    /// The feedback generator to use for drawer position changes.
    private var feedbackGenerator: UIImpactFeedbackGenerator?

    public func prepareFeedbackGenerator() {
        if feedbackGenerator == nil {
            feedbackGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackStyle.medium)
        }

        feedbackGenerator?.prepare()
    }

    public func triggerFeedbackGenerator() {
        feedbackGenerator?.impactOccurred()
    }

    /// Bounce the drawer to get user attention. Note: Only works in .bottomDrawer display mode and when the drawer is in .collapsed or .partiallyRevealed position.
    ///
    /// - Parameters:
    ///   - bounceHeight: The height to bounce
    ///   - speedMultiplier: The multiplier to apply to the default speed of the animation. Note, default speed is 0.75.
    public func bounceDrawer(bounceHeight: CGFloat = 50.0, speedMultiplier: Double = 0.75) {

        guard drawerPosition == .collapsed || drawerPosition == .partiallyRevealed else {
            print("Pulley: Error: You can only bounce the drawer when it's in the collapsed or partially revealed position.")
            return
        }

        guard currentDisplayMode == .bottomDrawer else {
            print("Pulley: Error: You can only bounce the drawer when it's in the .bottomDrawer display mode.")
            return
        }

        let drawerStartingBounds = drawerScrollView.bounds

        // Adapted from https://www.cocoanetics.com/2012/06/lets-bounce/
        let factors: [CGFloat] = [0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32,
            0, 24, 42, 54, 62, 64, 62, 54, 42, 24, 0, 18, 28, 32, 28, 18, 0]

        var values = [CGFloat]()

        for factor in factors {
            let positionOffset = (factor / 128.0) * bounceHeight
            values.append(drawerStartingBounds.origin.y + positionOffset)
        }

        let animation = CAKeyframeAnimation(keyPath: "bounds.origin.y")
        animation.repeatCount = 1
        animation.duration = (32.0/30.0) * speedMultiplier
        animation.fillMode = kCAFillModeForwards
        animation.values = values
        animation.isRemovedOnCompletion = true
        animation.autoreverses = false

        drawerScrollView.layer.add(animation, forKey: "bounceAnimation")
    }

    // MARK: PulleyDrawerViewControllerDelegate implementation for nested Pulley view controllers in drawers. Implemented here, rather than an extension because overriding extensions in subclasses isn't good practice. Some developers want to subclass Pulley and customize these behaviors, so we'll move them here.

    open func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        if let drawerContent = drawerContentViewController as? PulleyDrawerViewControllerDelegate,
            let collapsedHeight = drawerContent.collapsedDrawerHeight?(bottomSafeArea: bottomSafeArea) {
            return collapsedHeight
        }
        else {
            return defaultCollapsedHeight + bottomSafeArea
        }
    }

    open func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        if let drawerContent = drawerContentViewController as? PulleyDrawerViewControllerDelegate,
            let partialRevealHeight = drawerContent.partialRevealDrawerHeight?(bottomSafeArea: bottomSafeArea) {
            return partialRevealHeight
        }
        else {
            return defaultPartialRevealHeight + bottomSafeArea
        }
    }

    open func supportedDrawerPositions() -> [PulleyPosition] {
        if let drawerContent = drawerContentViewController as? PulleyDrawerViewControllerDelegate,
            let supportedPositions = drawerContent.supportedDrawerPositions?() {
            return supportedPositions
        }
        else {
            return PulleyPosition.all
        }
    }

    open func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if let drawerContent = drawerContentViewController as? PulleyDrawerViewControllerDelegate {
            drawerContent.drawerPositionDidChange?(drawer: drawer, bottomSafeArea: bottomSafeArea)
        }
    }

    open func makeUIAdjustmentsForFullscreen(progress: CGFloat, bottomSafeArea: CGFloat) {
        if let drawerContent = drawerContentViewController as? PulleyDrawerViewControllerDelegate {
            drawerContent.makeUIAdjustmentsForFullscreen?(progress: progress, bottomSafeArea: bottomSafeArea)
        }
    }

    open func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        if let drawerVCCompliant = drawerContentViewController as? PulleyDrawerViewControllerDelegate {
            drawerVCCompliant.drawerChangedDistanceFromBottom?(drawer: drawer, distance: distance, bottomSafeArea: bottomSafeArea)
        }
    }
}

// MARK: - UIViewController
extension PulleyViewController {
    override public func loadView() {
        super.loadView()

        // IB Support
        if primaryContentContainerView != nil {
            primaryContentContainerView.removeFromSuperview()
        }

        if drawerContentContainerView != nil {
            drawerContentContainerView.removeFromSuperview()
        }

        // Setup
        primaryContentContainer.backgroundColor = UIColor.white

        definesPresentationContext = true

        drawerScrollView.bounces = false
        drawerScrollView.delegate = self
        drawerScrollView.clipsToBounds = false
        drawerScrollView.showsVerticalScrollIndicator = false
        drawerScrollView.showsHorizontalScrollIndicator = false

        drawerScrollView.delaysContentTouches = delaysContentTouches
        drawerScrollView.canCancelContentTouches = canCancelContentTouches

        drawerScrollView.backgroundColor = UIColor.clear
        drawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast
        drawerScrollView.scrollsToTop = false
        drawerScrollView.touchDelegate = self

        drawerShadowView.layer.shadowOpacity = shadowOpacity
        drawerShadowView.layer.shadowRadius = shadowRadius
        drawerShadowView.backgroundColor = UIColor.clear

        drawerContentContainer.backgroundColor = UIColor.clear

        backgroundDimmingView.backgroundColor = backgroundDimmingColor
        backgroundDimmingView.isUserInteractionEnabled = false
        backgroundDimmingView.alpha = 0.0

        drawerBackgroundVisualEffectView?.clipsToBounds = true

        dimmingViewTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PulleyViewController.dimmingViewTapRecognizerAction(gestureRecognizer:)))
        backgroundDimmingView.addGestureRecognizer(dimmingViewTapRecognizer!)

        drawerScrollView.addSubview(drawerShadowView)

        if let drawerBackgroundVisualEffectView = drawerBackgroundVisualEffectView {
            drawerScrollView.addSubview(drawerBackgroundVisualEffectView)
            drawerBackgroundVisualEffectView.layer.cornerRadius = drawerCornerRadius
        }

        drawerScrollView.addSubview(drawerContentContainer)

        primaryContentContainer.backgroundColor = .white
        view.backgroundColor = .white

        view.addSubview(primaryContentContainer)
        view.addSubview(backgroundDimmingView)
        view.addSubview(drawerScrollView)

        primaryContentContainer.constrainToParent()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // IB Support
        if primaryContentViewController == nil || drawerContentViewController == nil {
            assert(primaryContentContainerView != nil && drawerContentContainerView != nil, "When instantiating from Interface Builder you must provide container views with an embedded view controller.")

            // Locate main content VC
            for child in childViewControllers {
                if child.view == primaryContentContainerView.subviews.first {
                    primaryContentViewController = child
                }

                if child.view == drawerContentContainerView.subviews.first {
                    drawerContentViewController = child
                }
            }

            assert(primaryContentViewController != nil && drawerContentViewController != nil, "Container views must contain an embedded view controller.")
        }

        enforceCanScrollDrawer()
        setDrawerPosition(position: initialDrawerPosition, animated: false)
        scrollViewDidScroll(drawerScrollView)

        callDelegateDrawerDisplayModeDidChange()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setNeedsSupportedDrawerPositionsUpdate()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        feedbackGenerator = nil
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Make sure our view controller views are subviews of the right view (Resolves #21 issue with changing the presentation context)

        // May be nil during initial layout
        if
            let primary = primaryContentViewController,
            primary.view.superview != nil,
            primary.view.superview != primaryContentContainer
        {
            primaryContentContainer.addSubview(primary.view)
            primaryContentContainer.sendSubview(toBack: primary.view)

            primary.view.constrainToParent()
        }

        // May be nil during initial layout
        if
            let drawer = drawerContentViewController,
            drawer.view.superview != nil,
            drawer.view.superview != drawerContentContainer
        {
            drawerContentContainer.addSubview(drawer.view)
            drawerContentContainer.sendSubview(toBack: drawer.view)

            drawer.view.constrainToParent()
        }

        currentDisplayMode = displayModeForCurrentLayout

        if currentDisplayMode == .bottomDrawer {
            layoutSubviewsForBottomDrawer()
        }
        else {
            layoutSubviewsForAutomaticAndTablet()
        }

        drawerContentContainer.transform = drawerScrollView.transform
        drawerShadowView.transform = drawerScrollView.transform

        maskBackgroundDimmingView()
        setDrawerPosition(position: drawerPosition, animated: false)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.notifyWhenInteractionChanges { [weak self] _ in
            guard let currentPosition = self?.drawerPosition else { return }
            self?.setDrawerPosition(position: currentPosition, animated: false)
        }
    }
}

// MARK: - Child View Controllers
extension PulleyViewController {
    /**
     Change the current primary content view controller (The one behind the drawer)

     - parameter controller: The controller to replace it with
     - parameter animated:   Whether or not to animate the change. Defaults to true.
     - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
     */
    public func setPrimaryContentViewController(controller: UIViewController, animated: Bool = true, completion: PulleyAnimationCompletionBlock?) {
        // Account for transition issue in iOS 11
        controller.view.frame = primaryContentContainer.bounds
        controller.view.layoutIfNeeded()

        if animated {
            UIView.transition(with: primaryContentContainer, duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] () -> Void in
                self?.primaryContentViewController = controller
                }, completion: completion)
        }
        else {
            primaryContentViewController = controller
            completion?(true)
        }
    }

    /**
     Change the current primary content view controller (The one behind the drawer). This method exists for backwards compatibility.

     - parameter controller: The controller to replace it with
     - parameter animated:   Whether or not to animate the change. Defaults to true.
     */
    public func setPrimaryContentViewController(controller: UIViewController, animated: Bool = true) {
        setPrimaryContentViewController(controller: controller, animated: animated, completion: nil)
    }

    /**
     Change the current drawer content view controller (The one inside the drawer)

     - parameter controller: The controller to replace it with
     - parameter animated:   Whether or not to animate the change.
     - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
     */
    public func setDrawerContentViewController(controller: UIViewController, animated: Bool = true, completion: PulleyAnimationCompletionBlock?) {
        // Account for transition issue in iOS 11
        controller.view.frame = drawerContentContainer.bounds
        controller.view.layoutIfNeeded()

        if animated {
            UIView.transition(with: drawerContentContainer, duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] () -> Void in
                self?.drawerContentViewController = controller
                self?.setDrawerPosition(position: self?.drawerPosition ?? .collapsed, animated: false)
                }, completion: completion)
        }
        else {
            drawerContentViewController = controller
            setDrawerPosition(position: drawerPosition, animated: false)

            completion?(true)
        }
    }

    /**
     Change the current drawer content view controller (The one inside the drawer). This method exists for backwards compatibility.

     - parameter controller: The controller to replace it with
     - parameter animated:   Whether or not to animate the change.
     */
    public func setDrawerContentViewController(controller: UIViewController, animated: Bool = true) {
        setDrawerContentViewController(controller: controller, animated: animated, completion: nil)
    }

    // MARK: Propagate child view controller style / status bar presentation based on drawer state

    override open var childViewControllerForStatusBarStyle: UIViewController? {
        if drawerPosition == .open {
            return drawerContentViewController
        }

        return primaryContentViewController
    }

    override open var childViewControllerForStatusBarHidden: UIViewController? {
        if drawerPosition == .open {
            return drawerContentViewController
        }

        return primaryContentViewController
    }
}

// MARK: - Gesture Recognizers
extension PulleyViewController {
    /// Add a gesture recognizer to the drawer scrollview
    ///
    /// - Parameter gestureRecognizer: The gesture recognizer to add
    public func addDrawerGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        drawerScrollView.addGestureRecognizer(gestureRecognizer)
    }

    /// Remove a gesture recognizer from the drawer scrollview
    ///
    /// - Parameter gestureRecognizer: The gesture recognizer to remove
    public func removeDrawerGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        drawerScrollView.removeGestureRecognizer(gestureRecognizer)
    }

    /// Get all gesture recognizers in the drawer scrollview
    public var drawerGestureRecognizers: [UIGestureRecognizer] {
        return drawerScrollView.gestureRecognizers ?? [UIGestureRecognizer]()
    }

    /// Get the drawer scrollview's pan gesture recognizer
    public var drawerPanGestureRecognizer: UIPanGestureRecognizer {
        return drawerScrollView.panGestureRecognizer
    }

    @objc func dimmingViewTapRecognizerAction(gestureRecognizer: UITapGestureRecognizer) {
        guard
            gestureRecognizer == dimmingViewTapRecognizer,
            gestureRecognizer.state == .ended
            else {
                return
        }
        setDrawerPosition(position: .collapsed, animated: true)
    }
}

// MARK: - PulleyPassthroughScrollViewDelegate
extension PulleyViewController: PulleyPassthroughScrollViewDelegate {

    func shouldTouchPassthroughScrollView(scrollView: PulleyPassthroughScrollView, point: CGPoint) -> Bool {
        return !drawerContentContainer.bounds.contains(drawerContentContainer.convert(point, from: scrollView))
    }

    func viewToReceiveTouch(scrollView: PulleyPassthroughScrollView, point: CGPoint) -> UIView {
        if currentDisplayMode == .bottomDrawer {
            if drawerPosition == .open {
                return backgroundDimmingView
            }

            return primaryContentContainer
        }
        else {
            if drawerContentContainer.bounds.contains(drawerContentContainer.convert(point, from: scrollView)) {
                return drawerContentViewController.view
            }

            return primaryContentContainer
        }
    }
}

// MARK: - UIScrollViewDelegate
extension PulleyViewController: UIScrollViewDelegate {

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView != drawerScrollView {
            return
        }

        var drawerStops: [CGFloat] = [CGFloat]()
        var currentDrawerPositionStop: CGFloat = 0.0

        let stopOptions = [(PulleyPosition.open, heightOfOpenDrawer),
                           (PulleyPosition.partiallyRevealed, defaultPartialRevealHeight),
                           (PulleyPosition.collapsed, defaultCollapsedHeight)]

        for (pos, height) in stopOptions where supportedPositions.contains(pos) {
            drawerStops.append(height)

            if drawerPosition == pos {
                currentDrawerPositionStop = height
            }
        }

        let lowestStop = drawerStops.min() ?? 0
        let distanceFromBottomOfView = lowestStop + lastDragTargetContentOffset.y

        let currentClosestStop = calculateCurrentClosestStop(drawerStops, distanceFromBottomOfView: distanceFromBottomOfView)
        let closestValidDrawerPosition = calculateClosestValidDrawerPosition(toStop: currentClosestStop)
        let snapModeToUse = closestValidDrawerPosition == drawerPosition ? snapMode : .nearestPosition

        let snapToPosition = calculateSnapToPosition(snapMode: snapModeToUse, closestValidDrawerPosition: closestValidDrawerPosition, currentDrawerPositionStop: currentDrawerPositionStop, distanceFromBottomOfView: distanceFromBottomOfView)
        setDrawerPosition(position: snapToPosition, animated: true)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView != drawerScrollView {
            return
        }

        lastDragTargetContentOffset = targetContentOffset.pointee

        // Halt intertia
        targetContentOffset.pointee = scrollView.contentOffset
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != drawerScrollView {
            return
        }

        let partialRevealHeight: CGFloat = (drawerContentViewController as? PulleyDrawerViewControllerDelegate)?.partialRevealDrawerHeight?(bottomSafeArea: pulleySafeAreaInsets.bottom) ?? defaultPartialRevealHeight

        let lowestStop = getStopList().min() ?? 0

        if (scrollView.contentOffset.y - pulleySafeAreaInsets.bottom) > partialRevealHeight - lowestStop && supportedPositions.contains(.open) {
            // Calculate percentage between partial and full reveal
            let fullRevealHeight = heightOfOpenDrawer
            let progress: CGFloat
            if fullRevealHeight == partialRevealHeight {
                progress = 1.0
            }
            else {
                progress = (scrollView.contentOffset.y - (partialRevealHeight - lowestStop)) / (fullRevealHeight - (partialRevealHeight))
            }

            callDelegateMakeUIAdjustmentsForFullscreen(progress: progress, bottomSafeArea: pulleySafeAreaInsets.bottom)

            backgroundDimmingView.alpha = progress * backgroundDimmingOpacity

            backgroundDimmingView.isUserInteractionEnabled = true
        }
        else {
            if backgroundDimmingView.alpha >= 0.001 {
                backgroundDimmingView.alpha = 0.0

                callDelegateMakeUIAdjustmentsForFullscreen(progress: 0.0, bottomSafeArea: pulleySafeAreaInsets.bottom)

                backgroundDimmingView.isUserInteractionEnabled = false
            }
        }

        callDelegateDrawerChangedDistanceFromBottom(distance: scrollView.contentOffset.y + lowestStop, bottomSafeArea: pulleySafeAreaInsets.bottom)

        // Move backgroundDimmingView to avoid drawer background beeing darkened
        backgroundDimmingView.frame = backgroundDimmingViewFrameForDrawerPosition(scrollView.contentOffset.y + lowestStop)

        syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode()
    }
}

// MARK: - Drawer Position
extension PulleyViewController {
    /**
     Set the drawer position, with an option to animate.

     - parameter position: The position to set the drawer to.
     - parameter animated: Whether or not to animate the change. (Default: true)
     - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called. (Default: nil)
     */
    public func setDrawerPosition(position: PulleyPosition, animated: Bool, completion: PulleyAnimationCompletionBlock? = nil) {
        guard supportedPositions.contains(position) else {
            print("PulleyViewController: You can't set the drawer position to something not supported by the current view controller contained in the drawer. If you haven't already, you may need to implement the PulleyDrawerViewControllerDelegate.")
            return
        }

        prepareFeedbackGenerator()

        drawerPosition = position

        let stopToMoveTo = calculateStopToMoveTo(drawerPosition: drawerPosition)
        let lowestStop = getStopList().min() ?? 0

        triggerFeedbackGenerator()

        if animated && view.window != nil {
            isAnimatingDrawerPosition = true
            UIView.animate(withDuration: animationDuration, delay: animationDelay, usingSpringWithDamping: animationSpringDamping, initialSpringVelocity: animationSpringInitialVelocity, options: animationOptions, animations: { [weak self] () -> Void in

                self?.drawerScrollView.setContentOffset(CGPoint(x: 0, y: stopToMoveTo - lowestStop), animated: false)

                // Move backgroundDimmingView to avoid drawer background being darkened
                self?.backgroundDimmingView.frame = self?.backgroundDimmingViewFrameForDrawerPosition(stopToMoveTo) ?? .zero

                if let drawer = self {
                    let bottomSafeArea = self?.pulleySafeAreaInsets.bottom ?? 0.0
                    self?.callDelegateDrawerPositionDidChange(bottomSafeArea: bottomSafeArea)

                    drawer.view.layoutIfNeeded()
                }
            }, completion: { [weak self] (completed) in
                self?.isAnimatingDrawerPosition = false
                self?.syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode()

                completion?(completed)
            })
        }
        else {
            drawerScrollView.setContentOffset(CGPoint(x: 0, y: stopToMoveTo - lowestStop), animated: false)

            // Move backgroundDimmingView to avoid drawer background being darkened
            backgroundDimmingView.frame = backgroundDimmingViewFrameForDrawerPosition(stopToMoveTo)

            callDelegateDrawerPositionDidChange(bottomSafeArea: pulleySafeAreaInsets.bottom)

            completion?(true)
        }
    }

    private func calculateStopToMoveTo(drawerPosition: PulleyPosition) -> CGFloat {
        let stopToMoveTo: CGFloat
        switch drawerPosition {
        case .collapsed:
            stopToMoveTo = collapsedHeight
        case .partiallyRevealed:
            stopToMoveTo = partialRevealHeight
        case .open:
            stopToMoveTo = heightOfOpenDrawer
        case .closed:
            stopToMoveTo = 0
        default:
            stopToMoveTo = 0
        }
        return stopToMoveTo
    }

    private func syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode() {

        guard currentDisplayMode == .leftSide else {
            return
        }

        let lowestStop = getStopList().min() ?? 0

        drawerContentContainer.frame = CGRect(x: 0.0, y: drawerScrollView.bounds.height - lowestStop, width: drawerScrollView.bounds.width, height: drawerScrollView.contentOffset.y + lowestStop + bounceOverflowMargin)
        drawerBackgroundVisualEffectView?.frame = drawerContentContainer.frame
        drawerShadowView.frame = drawerContentContainer.frame

        // Update rounding mask and shadows
        let borderPath = UIBezierPath(roundedRect: drawerContentContainer.bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: drawerCornerRadius, height: drawerCornerRadius)).cgPath

        let cardMaskLayer = CAShapeLayer()
        cardMaskLayer.path = borderPath
        cardMaskLayer.frame = drawerContentContainer.bounds
        cardMaskLayer.fillColor = UIColor.white.cgColor
        cardMaskLayer.backgroundColor = UIColor.clear.cgColor
        drawerContentContainer.layer.mask = cardMaskLayer

        if !isAnimatingDrawerPosition || borderPath.boundingBox.height < drawerShadowView.layer.shadowPath?.boundingBox.height ?? 0.0 {
            drawerShadowView.layer.shadowPath = borderPath
        }
    }

    /// Get a frame for moving backgroundDimmingView according to drawer position.
    ///
    /// - Parameter drawerPosition: drawer position in points
    /// - Returns: a frame for moving backgroundDimmingView according to drawer position
    private func backgroundDimmingViewFrameForDrawerPosition(_ drawerPosition: CGFloat) -> CGRect {
        let cutoutHeight = (2 * drawerCornerRadius)
        var backgroundDimmingViewFrame = backgroundDimmingView.frame
        backgroundDimmingViewFrame.origin.y = 0 - drawerPosition + cutoutHeight

        return backgroundDimmingViewFrame
    }

    /**
     Update the supported drawer positions allows by the Pulley Drawer
     */
    public func setNeedsSupportedDrawerPositionsUpdate() {
        if let drawerVCCompliant = drawerContentViewController as? PulleyDrawerViewControllerDelegate {
            supportedPositions = drawerVCCompliant.supportedDrawerPositions?() ?? PulleyPosition.all
        }
        else {
            supportedPositions = PulleyPosition.all
        }
    }
}

// MARK: - Private Helpers
extension PulleyViewController {
    private func calculateCurrentClosestStop(_ drawerStops: [CGFloat], distanceFromBottomOfView: CGFloat) -> CGFloat {
        let lowestStop = drawerStops.min() ?? 0
        var currentClosestStop = lowestStop
        for currentStop in drawerStops {
            if abs(currentStop - distanceFromBottomOfView) < abs(currentClosestStop - distanceFromBottomOfView) {
                currentClosestStop = currentStop
            }
        }

        return currentClosestStop
    }

    private func calculateClosestValidDrawerPosition(toStop currentClosestStop: CGFloat) -> PulleyPosition {
        var closestValidDrawerPosition = drawerPosition
        if abs(Float(currentClosestStop - heightOfOpenDrawer)) <= Float.ulpOfOne && supportedPositions.contains(.open) {
            closestValidDrawerPosition = .open
        }
        else if abs(Float(currentClosestStop - collapsedHeight)) <= Float.ulpOfOne && supportedPositions.contains(.collapsed) {
            closestValidDrawerPosition = .collapsed
        }
        else if supportedPositions.contains(.partiallyRevealed) {
            closestValidDrawerPosition = .partiallyRevealed
        }
        return closestValidDrawerPosition
    }

    private func calculateSnapToPosition(snapMode: PulleySnapMode, closestValidDrawerPosition: PulleyPosition, currentDrawerPositionStop: CGFloat, distanceFromBottomOfView: CGFloat) -> PulleyPosition {
        switch snapMode {
        case .nearestPosition:
            return closestValidDrawerPosition
        case .nearestPositionUnlessExceeded(let threshold):
            let distance = currentDrawerPositionStop - distanceFromBottomOfView
            var positionToSnapTo: PulleyPosition = drawerPosition

            if abs(distance) > threshold {
                if distance < 0 {
                    let orderedSupportedDrawerPositions = supportedPositions.sorted(by: { $0.rawValue < $1.rawValue }).filter({ $0 != .closed })

                    for position in orderedSupportedDrawerPositions {
                        if position.rawValue > drawerPosition.rawValue {
                            positionToSnapTo = position
                            break
                        }
                    }
                }
                else {
                    let orderedSupportedDrawerPositions = supportedPositions.sorted(by: { $0.rawValue > $1.rawValue }).filter({ $0 != .closed })

                    for position in orderedSupportedDrawerPositions {
                        if position.rawValue < drawerPosition.rawValue {
                            positionToSnapTo = position
                            break
                        }
                    }
                }
            }

            return positionToSnapTo
        }
    }
}

// MARK: Private State Updates
extension PulleyViewController {

    private func enforceCanScrollDrawer() {
        guard isViewLoaded else {
            return
        }

        drawerScrollView.isScrollEnabled = allowsUserDrawerPositionChange && supportedPositions.count > 1
    }

    func getStopList() -> [CGFloat] {

        var drawerStops = [CGFloat]()

        if supportedPositions.contains(.collapsed) {
            drawerStops.append(collapsedHeight)
        }

        if supportedPositions.contains(.partiallyRevealed) {
            drawerStops.append(partialRevealHeight)
        }

        if supportedPositions.contains(.open) {
            var safeAreaTopInset: CGFloat = 20.0

            if #available(iOS 11.0, *) {
                safeAreaTopInset = view.safeAreaInsets.top
            }

            drawerStops.append(view.bounds.height - topInset - safeAreaTopInset)
        }

        return drawerStops
    }

    /**
     Mask backgroundDimmingView layer to avoid drawer background being darkened.
     */
    private func maskBackgroundDimmingView() {
        let cutoutHeight = 2 * drawerCornerRadius
        let maskHeight = backgroundDimmingView.bounds.size.height - cutoutHeight - drawerScrollView.contentSize.height
        let maskWidth = backgroundDimmingView.bounds.width - pulleySafeAreaInsets.left - pulleySafeAreaInsets.right
        let drawerRect = CGRect(x: pulleySafeAreaInsets.left, y: maskHeight, width: maskWidth, height: drawerContentContainer.bounds.height)
        let path = UIBezierPath(roundedRect: drawerRect,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: drawerCornerRadius, height: drawerCornerRadius))
        let maskLayer = CAShapeLayer()

        // Invert mask to cut away the bottom part of the dimming view
        path.append(UIBezierPath(rect: backgroundDimmingView.bounds))
        maskLayer.fillRule = kCAFillRuleEvenOdd

        maskLayer.path = path.cgPath
        backgroundDimmingView.layer.mask = maskLayer
    }
}

// MARK: - Subview Layout
extension PulleyViewController {
    private func layoutSubviewsForAutomaticAndTablet() {
        // Bottom inset for safe area / bottomLayoutGuide
        if #available(iOS 11, *) {
            drawerScrollView.contentInsetAdjustmentBehavior = .scrollableAxes
        } else {
            automaticallyAdjustsScrollViewInsets = false
            drawerScrollView.contentInset = .zero
            drawerScrollView.scrollIndicatorInsets =  .zero
        }

        // Layout container

        let lowestStop = [(view.bounds.height - topInset - pulleySafeAreaInsets.top), collapsedHeight, partialRevealHeight].min() ?? 0

        if supportedPositions.contains(.open) {
            // Layout scrollview
            drawerScrollView.frame = CGRect(x: pulleySafeAreaInsets.left + panelInsetLeft, y: panelInsetTop + pulleySafeAreaInsets.top, width: panelWidth, height: heightOfOpenDrawer - panelInsetTop)
        }
        else {
            // Layout scrollview
            let adjustedTopInset: CGFloat = supportedPositions.contains(.partiallyRevealed) ? partialRevealHeight : collapsedHeight
            drawerScrollView.frame = CGRect(x: pulleySafeAreaInsets.left + panelInsetLeft, y: panelInsetTop + pulleySafeAreaInsets.top, width: panelWidth, height: adjustedTopInset)
        }

        syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode()

        drawerScrollView.contentSize = CGSize(width: drawerScrollView.bounds.width, height: view.bounds.height + (view.bounds.height - lowestStop))

        drawerScrollView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)

        backgroundDimmingView.isHidden = true
    }

    private func layoutSubviewsForBottomDrawer() {
        // Bottom inset for safe area / bottomLayoutGuide
        if #available(iOS 11, *) {
            drawerScrollView.contentInsetAdjustmentBehavior = .scrollableAxes
        } else {
            automaticallyAdjustsScrollViewInsets = false
            drawerScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomLayoutGuide.length, right: 0)
            drawerScrollView.scrollIndicatorInsets =  UIEdgeInsets(top: 0, left: 0, bottom: bottomLayoutGuide.length, right: 0) // (usefull if visible..)
        }

        let lowestStop = getStopList().min() ?? 0
        let adjustedLeftSafeArea = adjustDrawerHorizontalInsetToSafeArea ? pulleySafeAreaInsets.left : 0.0
        let adjustedRightSafeArea = adjustDrawerHorizontalInsetToSafeArea ? pulleySafeAreaInsets.right : 0.0

        let y: CGFloat
        let height: CGFloat
        if supportedPositions.contains(.open) {
            y = topInset + pulleySafeAreaInsets.top
            height = heightOfOpenDrawer
        }
        else {
            let adjustedTopInset = getStopList().max() ?? 0.0
            y = view.bounds.height - adjustedTopInset
            height = adjustedTopInset
        }
        drawerScrollView.frame = CGRect(x: adjustedLeftSafeArea, y: y, width: view.bounds.width - adjustedLeftSafeArea - adjustedRightSafeArea, height: height)

        drawerScrollView.addSubview(drawerShadowView)

        if let drawerBackgroundVisualEffectView = drawerBackgroundVisualEffectView {
            drawerScrollView.addSubview(drawerBackgroundVisualEffectView)
            drawerBackgroundVisualEffectView.layer.cornerRadius = drawerCornerRadius
        }

        drawerScrollView.addSubview(drawerContentContainer)

        drawerContentContainer.frame = CGRect(x: 0, y: drawerScrollView.bounds.height - lowestStop, width: drawerScrollView.bounds.width, height: drawerScrollView.bounds.height + bounceOverflowMargin)
        drawerBackgroundVisualEffectView?.frame = drawerContentContainer.frame
        drawerShadowView.frame = drawerContentContainer.frame
        drawerScrollView.contentSize = CGSize(width: drawerScrollView.bounds.width, height: (drawerScrollView.bounds.height - lowestStop) + drawerScrollView.bounds.height - pulleySafeAreaInsets.bottom + (bounceOverflowMargin - 5.0))

        // Update rounding mask and shadows
        let borderPath = UIBezierPath(roundedRect: drawerContentContainer.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: drawerCornerRadius, height: drawerCornerRadius)).cgPath

        let cardMaskLayer = CAShapeLayer()
        cardMaskLayer.path = borderPath
        cardMaskLayer.frame = drawerContentContainer.bounds
        cardMaskLayer.fillColor = UIColor.white.cgColor
        cardMaskLayer.backgroundColor = UIColor.clear.cgColor
        drawerContentContainer.layer.mask = cardMaskLayer
        drawerShadowView.layer.shadowPath = borderPath

        backgroundDimmingView.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: view.bounds.height + drawerScrollView.contentSize.height)

        drawerScrollView.transform = CGAffineTransform.identity

        backgroundDimmingView.isHidden = false
    }
}

// MARK: - Delegate Method Invocation
extension PulleyViewController {

    private var drawerContentDelegate: PulleyDrawerViewControllerDelegate? {
        return drawerContentViewController as? PulleyDrawerViewControllerDelegate
    }

    private var primaryContentDelegate: PulleyPrimaryContentControllerDelegate? {
        return primaryContentContainer as? PulleyPrimaryContentControllerDelegate
    }

    private func callDelegateDrawerDisplayModeDidChange() {
        delegate?.drawerDisplayModeDidChange?(drawer: self)
        drawerContentDelegate?.drawerDisplayModeDidChange?(drawer: self)
        primaryContentDelegate?.drawerDisplayModeDidChange?(drawer: self)
    }

    private func callDelegateDrawerPositionDidChange(bottomSafeArea: CGFloat) {
        delegate?.drawerPositionDidChange?(drawer: self, bottomSafeArea: bottomSafeArea)
        drawerContentDelegate?.drawerPositionDidChange?(drawer: self, bottomSafeArea: bottomSafeArea)
        primaryContentDelegate?.drawerPositionDidChange?(drawer: self, bottomSafeArea: bottomSafeArea)
    }

    private func callDelegateMakeUIAdjustmentsForFullscreen(progress: CGFloat, bottomSafeArea: CGFloat) {
        delegate?.makeUIAdjustmentsForFullscreen?(progress: progress, bottomSafeArea: bottomSafeArea)
        drawerContentDelegate?.makeUIAdjustmentsForFullscreen?(progress: progress, bottomSafeArea: bottomSafeArea)
        primaryContentDelegate?.makeUIAdjustmentsForFullscreen?(progress: progress, bottomSafeArea: bottomSafeArea)
    }

    private func callDelegateDrawerChangedDistanceFromBottom(distance: CGFloat, bottomSafeArea: CGFloat) {
        delegate?.drawerChangedDistanceFromBottom?(drawer: self, distance: distance, bottomSafeArea: bottomSafeArea)
        drawerContentDelegate?.drawerChangedDistanceFromBottom?(drawer: self, distance: distance, bottomSafeArea: bottomSafeArea)
        primaryContentDelegate?.drawerChangedDistanceFromBottom?(drawer: self, distance: distance, bottomSafeArea: bottomSafeArea)
    }
}

// MARK: - Rando computed properties - put them somewhere else
extension PulleyViewController {
    /// Access to the safe areas that Pulley is using for layout (provides compatibility for iOS < 11)
    public var pulleySafeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        }
        else {
            return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
        }
    }

    /// Get the current drawer distance. This value is equivalent in nature to the one delivered by PulleyDelegate's `drawerChangedDistanceFromBottom` callback.
    public var drawerDistanceFromBottom: (distance: CGFloat, bottomSafeArea: CGFloat) {
        if isViewLoaded {
            let lowestStop = getStopList().min() ?? 0.0
            return (distance: drawerScrollView.contentOffset.y + lowestStop, bottomSafeArea: pulleySafeAreaInsets.bottom)
        }

        return (distance: 0.0, bottomSafeArea: 0.0)
    }
}
