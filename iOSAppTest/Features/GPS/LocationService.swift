import Combine
import CoreLocation
import Foundation

protocol LocationService {
    /// 現在の権限状態（iOS 14+ では manager.authorizationStatus を参照）
    var authorizationStatus: CLAuthorizationStatus { get }

    /// 位置情報の更新を流すストリーム（Combine Publisher）
    /// - 成功: CLLocation が流れる
    /// - 失敗: Never = エラーは流れない（エラーは別途 errorPublisher で流す設計も可）
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }

    /// 位置情報のエラーを流すストリーム（任意）
    /// ViewModel側で「GPS取得失敗」を表示したい場合に使う
    var errorPublisher: AnyPublisher<Error, Never> { get }

    /// 権限リクエスト（初回のみシステムダイアログが出る）
    func requestWhenInUseAuthorization()

    /// 位置情報の取得を開始（CLLocationManager.startUpdatingLocation）
    func startUpdating()

    /// 位置情報の取得を停止（CLLocationManager.stopUpdatingLocation）
    func stopUpdating()
}
