//
//  DragIndicatorViewTests.swift
//  YBottomSheet
//
//  Created by Dev Karan on 10/01/23.
//  Copyright © 2023 Y Media Labs. All rights reserved.
//

import XCTest
@testable import YBottomSheet

final class DragIndicatorViewTests: XCTestCase {
    func test_initWithCoder() throws {
        let dragIndicatorView = DragIndicatorView()
        let sut = DragIndicatorView(coder: try makeCoder(for: dragIndicatorView))
        XCTAssertNil(sut)
    }
    
    func test_init_withDefaultValues() {
        let sut = makeSUT()
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.appearance.color, .tertiaryLabel)
        XCTAssertEqual(sut.appearance.layout.cornerRadius, 2)
        XCTAssertEqual(sut.appearance.layout.size, CGSize(width: 60, height: 4))
        XCTAssertEqual(sut.intrinsicContentSize, CGSize(width: 60, height: 4))
    }
    
    func test_init_withRandomValues() {
        let size = CGSize(width: 100, height: 20)
        let appearance = DragIndicatorView.Appearance(
            color: .red,
            layout: DragIndicatorView.Appearance.Layout(
                cornerRadius: 10,
                size: size
            )
        )
        let sut = makeSUT(appearance: appearance)
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.appearance.color, .red)
        XCTAssertEqual(sut.appearance.layout.cornerRadius, 10)
        XCTAssertEqual(sut.appearance.layout.size, size)
        XCTAssertEqual(sut.intrinsicContentSize, size)
    }
    
    func test_changeDragIndicatorColor() {
        let sut = makeSUT()
        let color: UIColor = .red

        XCTAssertNotEqual(sut.appearance.color, color)

        sut.appearance = DragIndicatorView.Appearance(color: color)
        
        XCTAssertEqual(sut.appearance.color, color)
    }
    
    func test_changeDragIndicatorLayout() {
        let sut = makeSUT()
        let size = CGSize(width: 100, height: 8)
        let radius: CGFloat = 4

        XCTAssertNotEqual(sut.appearance.layout.cornerRadius, radius)
        XCTAssertNotEqual(sut.appearance.layout.size, size)

        sut.appearance = DragIndicatorView.Appearance(
            layout: DragIndicatorView.Appearance.Layout(cornerRadius: radius, size: size)
        )

        XCTAssertEqual(sut.appearance.layout.cornerRadius, radius)
        XCTAssertEqual(sut.appearance.layout.size, size)
    }
}

private extension DragIndicatorViewTests {
    func makeSUT(
        appearance: DragIndicatorView.Appearance = .default,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DragIndicatorView {
        let sut = DragIndicatorView(appearance: appearance)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makeCoder(for view: UIView) throws -> NSCoder {
        let data = try NSKeyedArchiver.archivedData(withRootObject: view, requiringSecureCoding: false)
        return try NSKeyedUnarchiver(forReadingFrom: data)
    }
}
