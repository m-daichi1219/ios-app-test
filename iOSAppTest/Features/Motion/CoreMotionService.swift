import Combine
import CoreMotion
import Foundation

final class CoreMotionService: MotionService {
    // MARK: - Private Properties

    /// CoreMotionの本体（iOS標準API/アプリ全体で一つのインスタンスを共有することが推奨されている）
    private let motionManager = CMMotionManager()

    /// モーションデータを流すためのSubject
    private let motionSubject = PassthroughSubject<CMDeviceMotion, Never>()

    /// エラーを流すためのSubject
    private let errorSubject = PassthroughSubject<Error, Never>()

    // MARK: - Lifecycle

    init() {
        if !motionManager.isDeviceMotionAvailable {
            print("デバイスモーションが利用できません（シミュレータまたはセンサー非搭載デバイス")
        }
    }

    // MARK: - MotionService Protocol

    var isDeviceMotionAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    var motionPublisher: AnyPublisher<CMDeviceMotion, Never> {
        motionSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<any Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func startUpdates(interval: TimeInterval) {
        // センサーが利用不可の場合には処理を終了
        guard motionManager.isDeviceMotionAvailable else {
            let error = MotionServiceError.deviceMotionNotAvailable
            errorSubject.send(error)
            return
        }

        // 更新間隔を設定
        motionManager.deviceMotionUpdateInterval = interval

        // センサーデータの取得を開始
        // - queue: コールバックを受け取るスレッド（.main = メインスレッド）
        // - withHandler: データが来たら呼ばれるクロージャ
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error {
                self?.errorSubject.send(error)
                return
            }

            if let motion {
                self?.motionSubject.send(motion)
            }
        }

        func stopUpdates() {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        print("モーションセンサーの取得を停止しました")
    }
}

// MARK: - Error

enum MotionServiceError: LocalizedError {
    case deviceMotionNotAvailable

    var errorDescription: String? {
        switch self {
        case .deviceMotionNotAvailable:
            return "デバイスモーションが利用できません（シミュレータまたはセンサー非搭載デバイス）"
        }
    }
}
