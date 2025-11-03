import XCTest

// TODO: コードリーディング、テストケースの構造化

final class メニューリスト: XCTestCase {
    private var app: XCUIApplication!
    private var page: MainViewPage!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        page = MainViewPage(app: app)
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_リストの動作() {
        XCTContext.runActivity(named: "初期表示でメニューボタンが表示されていること") { _ in
            XCTAssertTrue(page.menuButton.waitForExistence(timeout: 5))
        }
        XCTContext.runActivity(named: "メニューを開くと各メニューボタンがタッチできること") { _ in
            page.openMenu()
            page.waitForAnyMenuItemToBeHittable(timeout: 5)
        }
    }

    /// - メニュー表示中はメイン画面が無効化状態であること
    func test_メニュー表示中はメイン画面が無効化状態であること() {
        page.openMenu()
        page.assertMenuOpen()
    }

    /// - メイン画面を選択するとメニューボタンが有効化されること
    func test_メイン画面を選択するとメニューボタンが有効化されること() {
        page.openMenu()
        page.closeMenuByTappingRightSide()
        page.assertMenuClosed()
    }
}

private struct MainViewPage {
    let app: XCUIApplication

    var menuButton: XCUIElement {
        app.buttons["メニュー"]
    }

    func openMenu(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), file: file, line: line)
        menuButton.tap()
        wait(isEnabled: false, for: menuButton, timeout: 5, file: file, line: line)
    }

    func assertMenuOpen(file: StaticString = #file, line: UInt = #line) {
        wait(isEnabled: false, for: menuButton, timeout: 5, file: file, line: line)
    }

    func assertMenuClosed(file: StaticString = #file, line: UInt = #line) {
        wait(isEnabled: true, for: menuButton, timeout: 5, file: file, line: line)
    }

    func closeMenuByTappingRightSide() {
        let screen = app.windows.firstMatch
        screen.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }

    func waitForAnyMenuItemToBeHittable(timeout: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        let candidates = ["BLE", "GPS", "Motion", "ホーム"].map { app.buttons[$0] }
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if candidates.contains(where: { $0.exists && $0.isHittable }) {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTFail("メニュー項目がタップ可能になりませんでした", file: file, line: line)
    }

    private func wait(isEnabled: Bool, for element: XCUIElement, timeout: TimeInterval, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "isEnabled == %@", NSNumber(value: isEnabled))
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [exp], timeout: timeout)
        XCTAssertEqual(result, .completed, "isEnabled が期待値(\(isEnabled))になりませんでした", file: file, line: line)
    }
}
