import XCTest
@testable import APProgressToolbar // Make sure this is your module name
import GTProgressBar
import SnapKit
import UIKit

// Mock delegate for testing cancel button
class MockProgressToolbarDelegate: NSObject, APProgressToolbarDelegate {
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
        toolbar = APProgressToolbar(frame: CGRect.zero)
        mockDelegate = MockProgressToolbarDelegate()
        toolbar.actionDelegate = mockDelegate
        superview.addSubview(toolbar)
        
        // Ensure layout is triggered so superview.bounds is correct
        superview.layoutIfNeeded()
    }
    
    override func tearDown() async throws {
        toolbar = nil
        mockDelegate = nil
        superview = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(toolbar.progressBar)
        XCTAssertFalse(toolbar.isShown)
    }
    
    func testSubviewsAreAdded() {
        XCTAssertTrue(toolbar.subviews.contains(toolbar.progressBar))
        
        // We can also find the private views by type (fragile but works for testing)
        let backgroundView = toolbar.subviews.first { $0.backgroundColor == .black }
        XCTAssertNotNil(backgroundView)
        
        let titleLabel = toolbar.subviews.first { $0 is UILabel }
        XCTAssertNotNil(titleLabel)
        
        let stopButton = toolbar.subviews.first { $0 is UIButton }
        XCTAssertNotNil(stopButton)
    }
    
    // MARK: - Show/Hide Tests
    
    func testShowWithoutAnimation() async {
        await toolbar.show(false)
        
        XCTAssertTrue(toolbar.isShown)
        XCTAssertFalse(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 745, width: 400, height: 55)) // 800 - 55
    }
    
    func testHideWithoutAnimation() async {
        await toolbar.show(false) // Start shown
        await toolbar.hide(false)
        
        XCTAssertFalse(toolbar.isShown)
        XCTAssertTrue(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 800, width: 400, height: 55))
    }
    
    func testShowWithAnimationCompletes() async {
        await toolbar.show(true)
        
        XCTAssertTrue(toolbar.isShown)
        XCTAssertFalse(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 745, width: 400, height: 55))
    }
    
    // MARK: - Added Tests
    
    func testHideWithAnimationCompletes() async {
        await toolbar.show(false) // Start shown
        await toolbar.hide(true)
        
        XCTAssertFalse(toolbar.isShown)
        XCTAssertTrue(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 800, width: 400, height: 55))
    }
    
    func testTextProperty() {
        let testString = "Uploading..."
        toolbar.text = testString
        
        // Fragile Test: Find the private label by its type.
        // This is necessary because 'titleLabel' is private.
        let titleLabel = toolbar.subviews.first { $0 is UILabel } as? UILabel
        
        XCTAssertNotNil(titleLabel, "Title label should exist")
        XCTAssertEqual(titleLabel?.text, testString)
    }
    
    func testCancelButtonTapped() {
        XCTAssertFalse(mockDelegate.cancelPressedCalled, "Delegate should not be called yet")
        
        // Fragile Test: Find the private button by its type.
        // This is necessary because 'stopButton' is private.
        let stopButton = toolbar.subviews.first { $0 is UIButton } as? UIButton
        XCTAssertNotNil(stopButton, "Stop button should exist")
        
        stopButton?.sendActions(for: .touchUpInside)
        
        XCTAssertTrue(mockDelegate.cancelPressedCalled, "Delegate should be called after tap")
    }
    
    func testDeviceOrientationDidChange() async {
        // 1. Show the toolbar
        await toolbar.show(false)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 745, width: 400, height: 55))

        // 2. Simulate an orientation change by resizing the superview
        superview.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

        // 3. Drive the handler directly — avoids racing the notification's main-queue dispatch.
        toolbar.deviceOrientationDidChange()

        // 4. Verify the toolbar repositioned itself relative to the new bounds
        XCTAssertTrue(toolbar.isShown)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 345, width: 800, height: 55)) // 400 - 55
    }
}
