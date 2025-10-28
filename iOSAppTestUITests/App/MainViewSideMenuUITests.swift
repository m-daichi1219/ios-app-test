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

    /// メニューを開き、メニュー外（オーバーレイ領域）をタップして閉じる
    func test_メニューを開き_オーバーレイタップで閉じる() {
        let menuButton = app.buttons["メニュー"] // MainViewの .accessibilityLabel("メニュー")
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "メニューボタンが見つかりません")

        // 1) 開く
        menuButton.tap()

        // 開いている間はメイン画面が .disabled → メニューボタンは無効
        wait(isEnabled: false, for: menuButton, timeout: 5)

        // 2) 右側（メニュー外＝オーバーレイが反応する領域）を座標タップして閉じる
        tapRightSideOfScreen()

        // 3) 閉じたらメニューボタンが再び有効になる
        wait(isEnabled: true, for: menuButton, timeout: 5)
    }

    // MARK: - ヘルパー

    /// 画面右側（メニュー幅より外）をタップ
    private func tapRightSideOfScreen() {
        let screen = app.windows.firstMatch
        // 画面の90%位置（右端寄り中央）をタップ
        let point = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        point.tap()
    }

    /// isEnabled の変化を待つ
    private func wait(isEnabled: Bool, for element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "isEnabled == %@", NSNumber(value: isEnabled))
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }
}
