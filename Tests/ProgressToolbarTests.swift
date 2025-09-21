import XCTest
@testable import APProgressToolbar // Your module name
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
    
    override func setUp() {
        super.setUp()
        superview = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800)) // Simulate a screen
        toolbar = APProgressToolbar(frame: CGRect.zero)
        mockDelegate = MockProgressToolbarDelegate()
        toolbar.actionDelegate = mockDelegate
        superview.addSubview(toolbar)
    }
    
    override func tearDown() {
        toolbar = nil
        mockDelegate = nil
        superview = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(toolbar.progressBar)
        XCTAssertFalse(toolbar.isShown)
    }
    
    func testSetupSubviews() {
        // Trigger setup via constraints update
        toolbar.setNeedsUpdateConstraints()
        toolbar.updateConstraints()
        
        XCTAssertTrue(toolbar.subviews.contains(toolbar.progressBar))
    }
 
    // MARK: - Show/Hide Tests
    
    func testShowWithoutAnimation() {
        toolbar.show(false)
        
        XCTAssertTrue(toolbar.isShown)
        XCTAssertFalse(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 745, width: 400, height: 55)) // 800 - 55
    }
    
    func testHideWithoutAnimation() {
        toolbar.show(false) // Start shown
        toolbar.hide(false)
        
        XCTAssertFalse(toolbar.isShown)
        XCTAssertTrue(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 800, width: 400, height: 55))
    }
    
    func testShowWithAnimationCompletes() {
        let expectation = XCTestExpectation(description: "Show animation completes")
        toolbar.show(true) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(toolbar.isShown)
        XCTAssertFalse(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 745, width: 400, height: 55))
    }
    
    func testHideWithAnimationCompletes() {
        toolbar.show(false) // Start shown
        let expectation = XCTestExpectation(description: "Hide animation completes")
        toolbar.hide(true) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0) // Accounts for 1s delay in hide animation
        XCTAssertFalse(toolbar.isShown)
        XCTAssertTrue(toolbar.isHidden)
        XCTAssertEqual(toolbar.frame, CGRect(x: 0, y: 800, width: 400, height: 55))
    }
 
}
