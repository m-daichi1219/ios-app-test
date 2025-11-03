import Combine
import CoreLocation
import Foundation

final class CoreLocationService: NSObject, LocationService {
    // MARK: - Private Properties

    /// CoreLocationの本体（iOS標準API）
    private let manager = CLLocationManager()

    /// 位置情報を流すためのSubject（Publisherの一種で、手動でイベントを送信できる）
    private let locationSubject = PassthroughSubject<CLLocation, Never>()

    /// エラーを流すためのSubject
    private let errorSubject = PassthroughSubject<Error, Never>()

    // MARK: - Lifecycle

    override init() {
        super.init()
        manager.delegate = self // デリゲートパターン：自分自身をデリゲートに設定
        manager.desiredAccuracy = kCLLocationAccuracyBest // 精度を最高に設定
        manager.distanceFilter = kCLDistanceFilterNone // 距離フィルタなし（全更新を受け取る）
    }

    // MARK: - LocationService Protocol

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus // iOS 14+ の推奨プロパティ
    }

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher() // 型を AnyPublisher に消去（具体的なSubject型を隠す）
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation() // CoreLocationに「位置情報の更新を開始」と指示
    }

    func stopUpdating() {
        manager.stopUpdatingLocation() // 更新を停止
    }
}

// MARK: - CLLocationManagerDelegate

extension CoreLocationService: CLLocationManagerDelegate {
    /// 位置情報が更新されたときに呼ばれるデリゲートメソッド
    /// - locations: 新しい位置情報の配列（通常は最後の1件が最新）
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 最新の位置情報だけをPublisherに流す
        guard let latest = locations.last else { return }
        locationSubject.send(latest) // Subjectに値を送信 → locationPublisher の購読者に届く
    }

    /// 位置情報の取得に失敗したときに呼ばれる
    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        errorSubject.send(error) // エラーを流す
    }

    /// 権限状態が変わったときに呼ばれる（iOS 14+）
    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        // 必要に応じてViewModel側に通知する設計も可能（今回は authorizationStatus を直接参照）
    }
}
