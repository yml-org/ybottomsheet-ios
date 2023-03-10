//
//  BottomSheetControllerTests.swift
//  YBottomSheet
//
//  Created by Dev Karan on 19/01/23.
//  Copyright © 2023 Y Media Labs. All rights reserved.
//

import XCTest
import YCoreUI
import YMatterType
@testable import YBottomSheet

// OK to have lots of test cases
// swiftlint:disable file_length

final class BottomSheetControllerTests: XCTestCase {
    var window: UIWindow!
    
    override func setUp() {
        super.setUp()
        window = UIWindow()
    }
    
    override func tearDown() {
        window = nil
        super.tearDown()
    }
    
    func test_initWithCoder() throws {
        let sut = BottomSheetController(coder: try makeCoder(for: UIView()))
        XCTAssertNil(sut)
    }
    
    func test_init_withViewControllerAsContentView() {
        let vc = UIViewController()
        vc.title = "Bottom Sheet"
        let sut = makeSUT(viewController: vc)
        XCTAssertNotNil(sut)
    }
    
    func test_init_withViewAsContentView() {
        let view = UIView()
        let sut = makeSUT(view: view, headerTitle: "Bottom Sheet")
        XCTAssertNotNil(sut)
    }
    
    func test_init_withRandomValues() {
        let headerTitle = "Bottom Sheet"
        let radius = CGFloat(Int.random(in: 24...48))
        let appearance = BottomSheetController.Appearance(
            indicatorAppearance: nil,
            headerAppearance: nil,
            layout: BottomSheetController.Appearance.Layout(cornerRadius: radius),
            dimmerColor: .green
        )
        let sut = makeSUT(view: UIView(), appearance: appearance, headerTitle: headerTitle)
        sut.loadViewIfNeeded()

        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isResizable)
        XCTAssertFalse(sut.hasHeader)
        XCTAssertTrue(sut.headerView.isHidden)
        XCTAssertTrue(sut.indicatorView.isHidden)
        XCTAssertEqual(sut.appearance.layout.cornerRadius, radius)
        XCTAssertEqual(sut.dimmerView.backgroundColor, appearance.dimmerColor)
    }
    
    func test_changeDragIndicatorColor() {
        let sut = makeSUT(viewController: UIViewController(), appearance: .defaultResizable)
        sut.loadViewIfNeeded()
        let color: UIColor = .red
        
        XCTAssertNotEqual(sut.indicatorView.backgroundColor, color)
        
        sut.appearance.indicatorAppearance?.color = color
        
        XCTAssertEqual(sut.indicatorView.backgroundColor, color)
    }

    func test_changeCornerRadius() {
        let sut = makeSUT(viewController: UIViewController())
        sut.loadViewIfNeeded()
        let cornerRadius = CGFloat(Int.random(in: 1...7))

        XCTAssertEqual(
            sut.sheetView.layer.cornerRadius,
            BottomSheetController.Appearance.Layout.default.cornerRadius
        )

        sut.appearance.layout.cornerRadius = cornerRadius

        XCTAssertEqual(sut.sheetView.layer.cornerRadius, cornerRadius)
    }

    func test_changeBeforeLoad_hasNoEffect() {
        let sut = makeSUT(viewController: UIViewController())
        let cornerRadius = CGFloat(Int.random(in: 1...7))

        sut.appearance.layout.cornerRadius = cornerRadius

        XCTAssertNotEqual(sut.sheetView.layer.cornerRadius, cornerRadius)
    }

    func test_hideHeaderView() {
        let sut = makeSUT(viewController: UIViewController())
        sut.loadViewIfNeeded()

        XCTAssertFalse(sut.headerView.isHidden)
        
        sut.appearance = BottomSheetController.Appearance(
            headerAppearance: nil
        )
        
        XCTAssertTrue(sut.headerView.isHidden)
        XCTAssertFalse(sut.hasHeader)
    }
    
    func test_hideDragIndicatorView() {
        let sut = makeSUT(viewController: UIViewController(), appearance: .defaultResizable)
        sut.loadViewIfNeeded()

        XCTAssertFalse(sut.indicatorView.isHidden)
        XCTAssertTrue(sut.isResizable)

        sut.appearance = BottomSheetController.Appearance(
            indicatorAppearance: nil
        )
        
        XCTAssertTrue(sut.indicatorView.isHidden)
        XCTAssertFalse(sut.isResizable)
    }
    
    func test_onDimmer() {
        let sut = SpyBottomSheetController(title: "", childView: UIView())
        
        XCTAssertFalse(sut.onDimmerTapped)
        XCTAssertFalse(sut.isDismissed)

        sut.simulateOnDimmerTap()
        
        XCTAssertTrue(sut.onDimmerTapped)
        XCTAssertTrue(sut.isDismissed)
    }
    
    func test_onSwipeDown() {
        let sut = SpyBottomSheetController(title: "", childView: UIView())
        
        XCTAssertFalse(sut.onSwipeDown)
        XCTAssertFalse(sut.isDismissed)

        sut.simulateOnSwipeDown()
        
        XCTAssertTrue(sut.onSwipeDown)
        XCTAssertTrue(sut.isDismissed)
    }
    
    func test_onDidDismiss() {
        let sut = SpyBottomSheetController(title: "", childView: UIView())
        
        XCTAssertFalse(sut.isDismissed)
        
        sut.simulateDismiss()
        
        XCTAssertTrue(sut.isDismissed)
    }

    func test_dragging_worksIfResizable() {
        let sut = SpyBottomSheetController(title: "", childView: ChildView(), appearance: .defaultResizable)
        sut.loadViewIfNeeded()
        XCTAssertFalse(sut.onDragging)

        let gesture = MockPanGesture()
        gesture.state = .began
        sut.simulateDragging(gesture)
        XCTAssertTrue(sut.onDragging)

        gesture.state = .ended
        sut.simulateDragging(gesture)
        XCTAssertFalse(sut.onDragging)
    }

    func test_dragging_doesNotWorkIfFixed() {
        let sut = SpyBottomSheetController(title: "", childView: ChildView())
        sut.loadViewIfNeeded()
        XCTAssertFalse(sut.onDragging)

        let gesture = MockPanGesture()
        gesture.state = .began
        sut.simulateDragging(gesture)
        XCTAssertFalse(sut.onDragging)
    }

    func test_dragging_slowDoesNotDismissSheet() {
        let sut = SpyBottomSheetController(title: "", childView: ChildView(), appearance: .defaultResizable)
        let threshold: CGFloat = 500
        sut.dismissThresholdVelocity = threshold
        sut.loadViewIfNeeded()

        let gesture = MockPanGesture()
        gesture.state = .ended
        gesture.velocity = CGPoint(x: 0, y: threshold - 1)
        sut.simulateDragging(gesture)
        XCTAssertFalse(sut.isDismissed)
    }

    func test_dragging_fastDismissesSheet() {
        let sut = SpyBottomSheetController(title: "", childView: ChildView(), appearance: .defaultResizable)
        let threshold: CGFloat = 500
        sut.dismissThresholdVelocity = threshold
        sut.loadViewIfNeeded()

        let gesture = MockPanGesture()
        gesture.state = .ended
        gesture.velocity = CGPoint(x: 0, y: threshold + 1)
        sut.simulateDragging(gesture)
        XCTAssertTrue(sut.isDismissed)
    }

    func test_draggingDown_resizes_view() {
        let appearance = BottomSheetController.Appearance(
            indicatorAppearance: .default,
            minimumContentHeight: 150
        )
        let sut = SpyBottomSheetController(title: "", childView: ChildView(), appearance: appearance)
        sut.loadViewIfNeeded()

        let gesture = MockPanGesture()
        gesture.state = .began
        sut.simulateDragging(gesture)
        let offset = sut.lastYOffset

        gesture.state = .changed
        let panDistance = CGFloat(Int.random(in: 20...100))
        gesture.translation = CGPoint(x: 0, y: panDistance)
        sut.simulateDragging(gesture)

        gesture.state = .ended
        sut.simulateDragging(gesture)
        XCTAssertEqual(sut.lastYOffset, offset + panDistance)
    }

    func test_draggingUp_resizes_view() {
        let appearance = BottomSheetController.Appearance(
            indicatorAppearance: .default,
            minimumContentHeight: 150
        )
        let sut = SpyBottomSheetController(title: "", childView: ChildView(), appearance: appearance)
        sut.loadViewIfNeeded()

        let gesture = MockPanGesture()
        gesture.state = .began
        sut.simulateDragging(gesture)
        let offset = sut.lastYOffset

        gesture.state = .changed
        let panDistance = CGFloat(Int.random(in: 20...100))
        gesture.translation = CGPoint(x: 0, y: -panDistance)
        sut.simulateDragging(gesture)

        gesture.state = .ended
        sut.simulateDragging(gesture)
        XCTAssertEqual(sut.lastYOffset, offset - panDistance)
    }

    func test_draggingDown_doesNotResizeViewBelowIntrinsicSize() {
        let sut = SpyBottomSheetController(title: "", childView: ChildView(), appearance: .defaultResizable)
        sut.loadViewIfNeeded()

        let gesture = MockPanGesture()
        gesture.state = .began
        sut.simulateDragging(gesture)
        let offset = sut.lastYOffset

        gesture.state = .changed
        let panDistance = CGFloat(Int.random(in: 20...100))
        gesture.translation = CGPoint(x: 0, y: panDistance)
        sut.simulateDragging(gesture)

        gesture.state = .ended
        sut.simulateDragging(gesture)
        XCTAssertEqual(sut.lastYOffset, offset)
    }

    func test_performEscape_dismissesSheet() {
        let sut = SpyBottomSheetController(childController: UIViewController())
        XCTAssertFalse(sut.isDismissed)
        _ = sut.accessibilityPerformEscape()
        XCTAssertTrue(sut.isDismissed)
    }

    func test_presentAnimator_returnsTheCorrectAnimator() throws {
        let parent = UIViewController()
        let sut = SpyBottomSheetController(childController: UIViewController())
        let animator = try XCTUnwrap(sut.animationController(forPresented: sut, presenting: parent, source: parent))
        XCTAssertTrue(animator.isKind(of: BottomSheetPresentAnimator.self))
    }

    func test_dismissAnimator_returnsTheCorrectAnimator() throws {
        let sut = SpyBottomSheetController(childController: UIViewController())
        let animator = try XCTUnwrap(sut.animationController(forDismissed: sut))
        XCTAssertTrue(animator.isKind(of: BottomSheetDismissAnimator.self))
    }

    func test_hasHeader_returnsTrueByDefault() {
        let sut1 = makeSUT(viewController: UIViewController())
        XCTAssertTrue(sut1.hasHeader)

        let sut2 = makeSUT(view: UIView())
        XCTAssertTrue(sut2.hasHeader)
    }

    func test_hasHeader_returnsFalseWhenNoHeader() {
        let sut = makeSUT(
            viewController: UIViewController(),
            appearance: BottomSheetController.Appearance(headerAppearance: nil)
        )
        XCTAssertFalse(sut.hasHeader)
    }

    func test_hasHeader_returnsFalseWhenChildControllerIsNavController() {
        let sut = makeSUT(viewController: UINavigationController(rootViewController: UIViewController()))
        XCTAssertFalse(sut.hasHeader)
    }
}

private extension BottomSheetControllerTests {
    func makeSUT(
        viewController: UIViewController,
        appearance: BottomSheetController.Appearance = .default,
        headerTitle: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BottomSheetController {
        let sut = BottomSheetController(
            childController: viewController,
            appearance: appearance
        )
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makeSUT(
        view: UIView,
        appearance: BottomSheetController.Appearance = .default,
        headerTitle: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BottomSheetController {
        let sut = BottomSheetController(
            title: headerTitle,
            childView: view,
            appearance: appearance
         )
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makeCoder(for view: UIView) throws -> NSCoder {
        let data = try NSKeyedArchiver.archivedData(withRootObject: view, requiringSecureCoding: false)
        return try NSKeyedUnarchiver(forReadingFrom: data)
    }
}

final class SpyBottomSheetController: BottomSheetController {
    var isDismissed = false
    var onSwipeDown = false
    var onDimmerTapped = false
    var onDragging = false

    override func didDismiss() {
        super.didDismiss()
        isDismissed = true
    }

    override func simulateOnSwipeDown() {
        super.simulateOnSwipeDown()
        onSwipeDown = true
    }

    override func simulateOnDimmerTap() {
        super.simulateOnDimmerTap()
        onDimmerTapped = true
    }

    @discardableResult
    override func simulateDragging(_ gesture: UIPanGestureRecognizer) -> Bool {
        guard super.simulateDragging(gesture) == true else { return false }
        switch gesture.state {
        case .began:
            onDragging = true
        case .ended, .cancelled, .failed:
            onDragging = false
        default:
            break
        }
        return true
    }
}

final class ChildView: UIView {
    override var intrinsicContentSize: CGSize { CGSize(width: 300, height: 300) }
}

final class MockPanGesture: UIPanGestureRecognizer {
    var translation: CGPoint = .zero
    var velocity: CGPoint = .zero

    override func translation(in view: UIView?) -> CGPoint { translation }
    override func velocity(in view: UIView?) -> CGPoint { velocity }
}
