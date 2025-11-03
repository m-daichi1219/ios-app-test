import Combine
import CoreLocation
import Foundation

/// テスト/プレビュー用のモック実装
/// 実際のGPSは使わず、ダミーの位置情報を流す
final class MockLocationService: LocationService {
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse // 常に許可済みと返す

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func requestWhenInUseAuthorization() {
        // モックなので何もしない（権限は既に許可されている想定）
    }

    func startUpdating() {
        // ダミーの位置情報を1秒ごとに流す（テスト用）
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let dummyLocation = CLLocation(
                latitude: 35.6812 + Double.random(in: -0.001 ... 0.001), // 東京付近 + ランダム
                longitude: 139.7671 + Double.random(in: -0.001 ... 0.001)
            )
            self?.locationSubject.send(dummyLocation)
        }
    }

    func stopUpdating() {
        // モックなので停止処理は省略（必要ならTimerを保持してinvalidate）
    }
}
