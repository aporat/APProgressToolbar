import XCTest
@testable import APProgressToolbar
import UIKit

@MainActor
final class MockProgressToolbarDelegate: APProgressToolbarDelegate {
    var cancelPressedCalled = false
    
    func didCancelButtonPressed(_ toolbar: APProgressToolbar) {
        cancelPressedCalled = true
    }
}

@MainActor
final class APProgressToolbarTests: XCTestCase {
    
    var toolbar: APProgressToolbar!
    var mockDelegate: MockProgressToolbarDelegate!
    var superview: UIView!
    
    override func setUp() async throws {
        try await super.setUp()
        
        superview = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        toolbar = APProgressToolbar(frame: .zero)
        mockDelegate = MockProgressToolbarDelegate()
        toolbar.actionDelegate = mockDelegate
        superview.addSubview(toolbar)
        superview.layoutIfNeeded()
    }
    
    override func tearDown() async throws {
        toolbar = nil
        mockDelegate = nil
        superview = nil
        try await super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertFalse(toolbar.isShown)
        XCTAssertEqual(toolbar.percentLabel.text, "0%")
    }
    
    func testShowPositionsCardAboveBottom() async {
        await toolbar.show(false)
        
        XCTAssertTrue(toolbar.isShown)
        XCTAssertFalse(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame.minX, APProgressToolbar.Layout.horizontalInset)
        XCTAssertEqual(toolbar.frame.width, 400 - APProgressToolbar.Layout.horizontalInset * 2)
        XCTAssertEqual(toolbar.frame.maxY, 800 - APProgressToolbar.Layout.bottomInset)
        XCTAssertEqual(toolbar.frame.height, APProgressToolbar.Layout.cardHeight)
    }
    
    func testHideMovesCardOffscreen() async {
        await toolbar.show(false)
        await toolbar.hide(false)
        
        XCTAssertFalse(toolbar.isShown)
        XCTAssertTrue(toolbar.isHidden)
        XCTAssertGreaterThanOrEqual(toolbar.frame.minY, 800)
    }
    
    func testShowDuringAnimatedHideKeepsCardVisible() async {
        await toolbar.show(false)
        
        let hide = Task { await toolbar.hide(true) }
        try? await Task.sleep(for: .milliseconds(100))
        await toolbar.show(false)
        await hide.value
        
        XCTAssertTrue(toolbar.isShown)
        XCTAssertFalse(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame.maxY, 800 - APProgressToolbar.Layout.bottomInset)
    }
    
    func testExtraBottomOffsetRaisesCard() async {
        toolbar.extraBottomOffset = 50
        await toolbar.show(false)
        
        XCTAssertEqual(toolbar.frame.maxY, 800 - APProgressToolbar.Layout.bottomInset - 50)
    }
    
    func testProgressClampsAndUpdatesPercent() {
        toolbar.progressBar.progress = 1.5
        XCTAssertEqual(toolbar.progressBar.progress, 1)
        XCTAssertEqual(toolbar.percentLabel.text, "100%")
        
        toolbar.progressBar.progress = -0.2
        XCTAssertEqual(toolbar.progressBar.progress, 0)
        XCTAssertEqual(toolbar.percentLabel.text, "0%")
        
        toolbar.progressBar.progress = 0.456
        XCTAssertEqual(toolbar.percentLabel.text, "46%")
    }
    
    func testTextUpdatesTitle() {
        toolbar.text = "Loading…"
        XCTAssertEqual(toolbar.titleLabel.text, "Loading…")
    }
    
    func testCancelButtonNotifiesDelegate() async {
        await toolbar.show(false)
        toolbar.stopButton.sendActions(for: .touchUpInside)
        XCTAssertTrue(mockDelegate.cancelPressedCalled)
    }
    
    func testCancelButtonDisabledWhileHidden() async {
        await toolbar.show(false)
        await toolbar.hide(false)
        XCTAssertFalse(toolbar.stopButton.isEnabled)
    }
}
