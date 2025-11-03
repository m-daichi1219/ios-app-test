import Combine
import CoreMotion
import Foundation

protocol MotionService {
    /// デバイスモーション（センサーフュージョン済みデータ）が利用可能か
    var isDeviceMotionAvailable: Bool { get }

    /// モーションデータの更新を流すストリーム（Combine Publisher）
    /// - 成功: CMDeviceMotion が流れる
    /// - 失敗: Never = エラーは流れない（エラーは別途 errorPublisher で流す設計も可）
    var motionPublisher: AnyPublisher<CMDeviceMotion, Never> { get }

    /// エラーを流すストリーム（任意）
    /// ViewModel側で「センサー取得失敗」を表示したい場合に使う
    var errorPublisher: AnyPublisher<Error, Never> { get }

    /// センサーデータの取得を開始
    /// - Parameter interval: 更新間隔（秒）。例: 0.1 = 10Hz
    func startUpdates(interval: TimeInterval)

    /// センサーデータの取得を停止
    func stopUpdates()
}
