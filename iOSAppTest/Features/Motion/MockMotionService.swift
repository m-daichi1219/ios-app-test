import Combine
import CoreMotion
import Foundation

/// テスト/プレビュー用のモック実装
/// 実際のセンサーは使わず、ダミーのモーションデータを流す
final class MockMotionService: MotionService {
    private let motionSubject = PassthroughSubject<CMDeviceMotion, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    private var timer: Timer?

    var isDeviceMotionAvailable: Bool = true // 常に利用可能と返す

    var motionPublisher: AnyPublisher<CMDeviceMotion, Never> {
        motionSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func startUpdates(interval: TimeInterval) {
        // タイマーで定期的にダミーデータを流す
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            // ダミーの CMDeviceMotion を作成するのは困難なため、実際のテストでは別の方法を使う
            // ここでは説明用に省略
            print("🧪 MockMotionService: ダミーデータを送信（実装省略）")
        }
    }

    func stopUpdates() {
        timer?.invalidate()
        timer = nil
    }
}
