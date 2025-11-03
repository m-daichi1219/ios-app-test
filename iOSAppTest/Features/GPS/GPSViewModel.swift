import Combine
import CoreLocation
import Foundation

/// GPS 計測の状態を管理する ViewModel
/// @MainActor: すべてのプロパティ/メソッドがメインスレッドで実行される（UI更新の安全性）
@MainActor
final class GPSViewModel: ObservableObject {
    // MARK: - Published Properties（View が監視するプロパティ）

    /// 計測中かどうか（ボタンのラベル切替に使う）
    @Published var isRecording = false

    /// 状態メッセージ（「計測中...」「停止しました」等）
    @Published var statusMessage = "準備完了"

    /// 画面に表示する位置情報（最新10件のみ表示して重くしない）
    @Published var displayLocations: [LocationDisplayData] = []

    /// 蓄積した全データ件数（表示用）
    @Published var recordedCount = 0

    // MARK: - Private Properties

    /// 位置情報サービス（DI = 依存性注入で外から渡す）
    private let locationService: LocationService

    /// 計測中に蓄積する全位置情報（停止時にCSVへ渡す）
    private var recordedLocations: [CLLocation] = []

    /// Combine の購読を保持する箱（deinit 時に自動キャンセル）
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    /// 初期化（依存性注入 = DI）
    /// - Parameter locationService: 本番は CoreLocationService、テストは MockLocationService を渡す
    init(locationService: LocationService) {
        self.locationService = locationService
        setupBindings() // Combine でデータの流れを接続
    }

    // MARK: - Public Methods（View から呼ばれる）

    /// 計測を開始/停止するトグル
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Private Methods

    /// Combine でデータの流れを接続（初期化時に1回だけ呼ぶ）
    private func setupBindings() {
        // locationService.locationPublisher を購読
        // 位置情報が流れてきたら recordLocation(_:) を呼ぶ
        locationService.locationPublisher
            .sink { [weak self] location in
                self?.recordLocation(location)
            }
            .store(in: &cancellables) // 購読をcancellablesに保存（deinitで自動キャンセル）

        // エラーが流れてきたら statusMessage に反映
        locationService.errorPublisher
            .sink { [weak self] error in
                self?.statusMessage = "エラー: \(error.localizedDescription)"
            }
            .store(in: &cancellables)
    }

    /// 計測開始
    private func startRecording() {
        // 権限チェック
        let status = locationService.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            statusMessage = "位置情報が許可されていません"
            return
        }

        // 前回のデータをクリア
        recordedLocations.removeAll()
        displayLocations.removeAll()
        recordedCount = 0

        isRecording = true
        statusMessage = "計測中..."
        locationService.startUpdating() // 位置情報の取得開始
    }

    /// 計測停止
    private func stopRecording() {
        isRecording = false
        locationService.stopUpdating() // 位置情報の取得停止

        guard !recordedLocations.isEmpty else {
            statusMessage = "データがありません"
            return
        }

        Task {
            await exportToCSV()
        }
    }

    /// CSV出力（非同期）
    private func exportToCSV() async {
        do {
            // CSVExporter で保存（throws なので try で呼ぶ）
            let fileURL = try CSVExporter.exportLocations(recordedLocations)

            // 成功メッセージ
            statusMessage = "保存しました（\(recordedLocations.count)件）"

            // ファイルパスをコンソールに出力（Xcode のデバッグエリアで確認）
            print("CSV保存成功: \(fileURL.path)")
            print("ファイルを取り出すには:")
            print("Xcode > Window > Devices and Simulators > 実機を選択")
            print("> Installed Apps > iOSAppTest > 歯車アイコン > Download Container")

        } catch {
            // エラー時のメッセージ
            statusMessage = "保存に失敗しました: \(error.localizedDescription)"
            print("CSV保存エラー: \(error)")
        }
    }

    /// 位置情報が流れてきたときに呼ばれる（Combine経由）
    private func recordLocation(_ location: CLLocation) {
        guard isRecording else { return } // 計測中のみ記録

        recordedLocations.append(location) // 全データを蓄積
        recordedCount = recordedLocations.count

        // コンソールに詳細データを出力（デバッグ用）
        printLocationDetail(location, index: recordedCount)

        // 画面表示用に最新10件のみ保持（全件表示すると重い）
        let displayData = LocationDisplayData(location: location)
        displayLocations.append(displayData)
        if displayLocations.count > 10 {
            displayLocations.removeFirst() // 古いものを削除
        }
    }

    // MARK: - DEBUG FUNC

    /// 位置情報の詳細をコンソールに出力
    private func printLocationDetail(_ location: CLLocation, index: Int) {
        print("""

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📍 位置情報 #\(index)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🕐 取得日時: \(formatDate(location.timestamp))

        📌 座標
           緯度 (latitude):  \(location.coordinate.latitude)°
           経度 (longitude): \(location.coordinate.longitude)°

        📏 高度・速度
           高度 (altitude):      \(location.altitude) m
           速度 (speed):          \(location.speed) m/s (\(location.speed * 3.6) km/h)
           進行方向 (course):     \(location.course)°

        🎯 精度
           水平精度 (horizontalAccuracy): \(location.horizontalAccuracy) m
           垂直精度 (verticalAccuracy):   \(location.verticalAccuracy) m
           \(accuracyDescription(location.horizontalAccuracy))

        🌐 その他
           床 (floor):              \(location.floor?.level ?? 0) 階
           ソース (sourceInformation): \(String(describing: location.sourceInformation))
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }

    /// 日時フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    /// 精度の説明
    private func accuracyDescription(_ accuracy: Double) -> String {
        if accuracy < 0 {
            return "⚠️ 精度情報なし（無効な値）"
        } else if accuracy < 10 {
            return "✅ 非常に高精度（10m未満）"
        } else if accuracy < 50 {
            return "✅ 高精度（50m未満）"
        } else if accuracy < 100 {
            return "⚠️ 中精度（100m未満）"
        } else {
            return "❌ 低精度（100m以上）"
        }
    }
}

// MARK: - Display Data Model

/// 画面表示用の軽量データ（CLLocation はクラスで重いため、必要な情報だけ抜き出す）
struct LocationDisplayData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double

    init(location: CLLocation) {
        timestamp = location.timestamp
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        horizontalAccuracy = location.horizontalAccuracy
    }
}
