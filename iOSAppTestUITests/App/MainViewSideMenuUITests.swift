import XCTest

final class MainViewSideMenuUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_メニューを開き_オーバーレイタップで閉じる() {
        // 1) 左上の「メニュー」ボタンをタップしてメニューを開く
        let menuButton = app.buttons["メニュー"] // MainViewの .accessibilityLabel("メニュー")
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "メニューボタンが見つかりません")
        menuButton.tap()

        // 2) メニュー開時のみ表示されるオーバーレイが現れ、タップ可能になるまで待機
        let overlay = app.otherElements["overlay"] // MainViewの .accessibilityIdentifier("overlay")
        waitToBeHittable(overlay, timeout: 5)

        // 3) オーバーレイをタップしてメニューを閉じる
        overlay.tap()

        // 4) オーバーレイが消える（＝メニューが閉じる）まで待機
        waitToBeNotHittable(overlay, timeout: 5)
    }

    // MARK: - ヘルパー

    private func waitToBeHittable(_ element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "hittable == true")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }

    private func waitToBeNotHittable(_ element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "hittable == false")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }
}
