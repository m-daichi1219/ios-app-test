import Combine
import CoreMotion
import Foundation
import UIKit

@MainActor
final class MotionViewModel: ObservableObject {
    // MARK: - Published Properties

    /// 計測中か否か
    @Published var isRecording: Bool = false

    /// 状態メッセージ
    @Published var statusMessage: String = "準備完了"

    /// 画面に表示するモーションデータ
    @Published var displayMotions: [MotionDisplayData] = []

    /// 蓄積した全データ件数（表示用）
    @Published var recordedCount = 0

    // MARK: - Private Properties

    /// モーションサービス（DI = 依存性注入で外から渡す）
    private let motionService: MotionService

    /// 計測中に蓄積する全モーションデータ（停止時にCSVへ渡す）
    private var recordedMotions: [CMDeviceMotion] = []

    /// Combine の購読を保持する箱（deinit 時に自動キャンセル）
    private var cancellables = Set<AnyCancellable>()

    /// 自動停止用のタイマー（30分）
    private var autoStopTimer: Timer?

    /// 最大計測時間（秒）
    private let maxRecordingDurationSec: TimeInterval = 10

    /// センサー更新間隔（秒）
    private let updateInterval: TimeInterval = 0.1 // 10Hz（1秒に10回）

    // MARK: - Lifecycle

    init(motionService: MotionService) {
        self.motionService = motionService
        setupBindings() // Combine でデータの流れを接続
        setupLifecycleObservers() // アプリのライフサイクル監視
    }

    deinit {
        autoStopTimer?.invalidate()
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
        // motionService.motionPublisher を購読
        // モーションデータが流れてきたら recordMotion(_:) を呼ぶ
        motionService.motionPublisher
            .sink { [weak self] motion in
                self?.recordMotion(motion)
            }
            .store(in: &cancellables)

        // エラーが流れてきたら statusMessage に反映
        motionService.errorPublisher
            .sink { [weak self] error in
                self?.statusMessage = "エラー: \(error.localizedDescription)"
            }
            .store(in: &cancellables)
    }

    /// アプリのライフサイクルを監視
    private func setupLifecycleObservers() {
        // アプリがバックグラウンドに移行したら自動停止
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleDidEnterBackground()
            }
            .store(in: &cancellables)
    }

    /// バックグラウンド移行時の処理
    private func handleDidEnterBackground() {
        guard isRecording else { return }

        print("バックグラウンドに移行したため、計測を自動停止します")
        stopRecording(reason: "バックグラウンド移行により自動停止")
    }

    /// 計測開始
    private func startRecording() {
        // センサーが利用可能か確認
        guard motionService.isDeviceMotionAvailable else {
            statusMessage = "デバイスモーションが利用できません"
            return
        }

        // 前回のデータをクリア
        recordedMotions.removeAll()
        displayMotions.removeAll()
        recordedCount = 0

        isRecording = true
        statusMessage = "計測中..."
        motionService.startUpdates(interval: updateInterval) // センサーデータの取得開始

        print("📱 モーション計測を開始しました（間隔: \(updateInterval)秒）")

        // 自動停止するタイマーをセット
        startAutoStopTimer()
    }

    /// 自動停止タイマーを開始
    private func startAutoStopTimer() {
        autoStopTimer?.invalidate()

        autoStopTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDurationSec, repeats: false) { [weak self] _ in
            self?.handleAutoStop()
        }

        print("自動停止します")
    }

    /// 自動停止の処理
    private func handleAutoStop() {
        guard isRecording else { return }

        print("計測を自動停止します")
        stopRecording(reason: "時間経過により自動停止")
    }

    /// 計測停止 → CSV出力
    private func stopRecording(reason: String? = nil) {
        isRecording = false
        motionService.stopUpdates() // センサーデータの取得停止

        // タイマーを停止
        autoStopTimer?.invalidate()
        autoStopTimer = nil

        // データが0件なら何もしない
        guard !recordedMotions.isEmpty else {
            statusMessage = reason ?? "データがありません"
            return
        }

        // CSV出力を実行（非同期タスクで呼ぶことでメインスレッドをブロックしない）
        Task {
            await exportToCSV(reason: reason)
        }
    }

    /// CSV出力の実装（非同期処理）
    private func exportToCSV(reason: String? = nil) async {
        do {
            // CSVExporter で保存（次のステップで実装）
            let fileURL = try CSVExporter.exportMotions(recordedMotions)

            if let reason {
                statusMessage = "\(reason)（\(recordedMotions.count)件保存）"
            } else {
                statusMessage = "保存しました（\(recordedMotions.count)件）"
            }

            print("CSV保存成功: \(fileURL.path)")
            print("ファイルを取り出すには:")
            print("Xcode > Window > Devices and Simulators > 実機を選択")
            print("> Installed Apps > iOSAppTest > 歯車アイコン > Download Container")

        } catch {
            statusMessage = "保存に失敗しました: \(error.localizedDescription)"
            print("CSV保存エラー: \(error)")
        }
    }

    /// モーションデータが流れてきたときに呼ばれる（Combine経由）
    private func recordMotion(_ motion: CMDeviceMotion) {
        guard isRecording else { return } // 計測中のみ記録

        recordedMotions.append(motion) // 全データを蓄積
        recordedCount = recordedMotions.count

        // デバッグ用: コンソールに詳細データを出力（最初の10件のみ）
        if recordedCount <= 10 {
            printMotionDetail(motion, index: recordedCount)
        }

        // 画面表示用に最新10件のみ保持（全件表示すると重い）
        let displayData = MotionDisplayData(motion: motion)
        displayMotions.append(displayData)
        if displayMotions.count > 10 {
            displayMotions.removeFirst() // 古いものを削除
        }
    }

    /// モーションデータの詳細をコンソールに出力（デバッグ用）
    private func printMotionDetail(_ motion: CMDeviceMotion, index: Int) {
        let attitude = motion.attitude
        let rotation = motion.rotationRate
        let userAccel = motion.userAcceleration
        let gravity = motion.gravity

        print("""

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📱 モーションデータ #\(index)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🕐 取得日時: \(formatDate(motion.timestamp))

        🧭 姿勢（Attitude）
           roll (横回転):  \(String(format: "%.3f", attitude.roll)) rad (\(String(format: "%.1f", attitude.roll * 180 / .pi))°)
           pitch (縦回転): \(String(format: "%.3f", attitude.pitch)) rad (\(String(format: "%.1f", attitude.pitch * 180 / .pi))°)
           yaw (方位):     \(String(format: "%.3f", attitude.yaw)) rad (\(String(format: "%.1f", attitude.yaw * 180 / .pi))°)

        🔄 回転速度（Rotation Rate）
           x: \(String(format: "%.3f", rotation.x)) rad/s
           y: \(String(format: "%.3f", rotation.y)) rad/s
           z: \(String(format: "%.3f", rotation.z)) rad/s

        📍 ユーザー加速度（User Acceleration, 重力除く）
           x: \(String(format: "%.3f", userAccel.x)) G
           y: \(String(format: "%.3f", userAccel.y)) G
           z: \(String(format: "%.3f", userAccel.z)) G

        ⬇️ 重力（Gravity）
           x: \(String(format: "%.3f", gravity.x)) G
           y: \(String(format: "%.3f", gravity.y)) G
           z: \(String(format: "%.3f", gravity.z)) G
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }

    /// タイムスタンプを日時に変換
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSinceReferenceDate: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Display Data Model

/// 画面表示用の軽量データ（CMDeviceMotionはクラスで重いため、必要な情報だけ抜き出す）
struct MotionDisplayData: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval
    let roll: Double // ラジアン
    let pitch: Double // ラジアン
    let yaw: Double // ラジアン
    let userAccelerationX: Double // G
    let userAccelerationY: Double // G
    let userAccelerationZ: Double // G

    init(motion: CMDeviceMotion) {
        timestamp = motion.timestamp
        roll = motion.attitude.roll
        pitch = motion.attitude.pitch
        yaw = motion.attitude.yaw
        userAccelerationX = motion.userAcceleration.x
        userAccelerationY = motion.userAcceleration.y
        userAccelerationZ = motion.userAcceleration.z
    }

    /// 日時に変換
    var date: Date {
        Date(timeIntervalSinceReferenceDate: timestamp)
    }

    /// ラジアンを度に変換
    func toDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
