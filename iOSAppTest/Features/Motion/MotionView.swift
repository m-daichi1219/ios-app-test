import CoreMotion
import SwiftUI

// TODO: すでに許可済みのケース
private final class MotionPrompt {
    private let activityManager = CMMotionActivityManager()
    func request() {
        // 直近範囲のクエリで初回ダイアログ（Motionとフィットネス）を表示
        activityManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, _ in }
    }
}

struct MotionView: View {
    // MARK: - Properties

    @StateObject private var viewModel = MotionViewModel(
        motionService: CoreMotionService()
    )
    /// センサー非対応デバイスのアラート表示状態
    @State private var showUnavailableAlert = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // タイトル
            Text("モーション計測")
                .font(.title2)
                .bold()

            // 状態メッセージ
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // データ件数表示
            Text("記録件数: \(viewModel.recordedCount)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // 開始/停止ボタン
            Button {
                handleRecordingToggle()
            } label: {
                Text(viewModel.isRecording ? "停止" : "開始")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // 最新データのリスト表示（最新10件）
            List(viewModel.displayMotions) { data in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("📱 #\(viewModel.displayMotions.firstIndex(where: { $0.id == data.id })! + 1)")
                            .font(.headline)
                        Spacer()
                        Text(data.date, formatter: timeFormatter)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Group {
                        HStack {
                            Text("🧭 姿勢（Attitude）")
                                .font(.subheadline)
                                .bold()
                            Spacer()
                        }
                        Text("Roll (横回転): \(data.toDegrees(data.roll), specifier: "%.1f")°")
                        Text("Pitch (縦回転): \(data.toDegrees(data.pitch), specifier: "%.1f")°")
                        Text("Yaw (方位): \(data.toDegrees(data.yaw), specifier: "%.1f")°")
                    }
                    .font(.caption)

                    Divider()

                    Group {
                        HStack {
                            Text("📍 ユーザー加速度（重力除く）")
                                .font(.subheadline)
                                .bold()
                            Spacer()
                        }
                        Text("X: \(data.userAccelerationX, specifier: "%.3f") G")
                        Text("Y: \(data.userAccelerationY, specifier: "%.3f") G")
                        Text("Z: \(data.userAccelerationZ, specifier: "%.3f") G")
                    }
                    .font(.caption)

                    Divider()

                    // 加速度の強さ（ベクトルの大きさ）
                    let magnitude = sqrt(
                        data.userAccelerationX * data.userAccelerationX +
                            data.userAccelerationY * data.userAccelerationY +
                            data.userAccelerationZ * data.userAccelerationZ
                    )
                    HStack {
                        Text("加速度の強さ:")
                            .font(.caption)
                            .bold()
                        Text("\(magnitude, specifier: "%.3f") G")
                            .font(.caption)
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)

            Spacer()
        }
        .padding()
        .alert("センサーが利用できません", isPresented: $showUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("このデバイスはモーションセンサーに対応していません。実機で試してください。")
        }
    }

    // MARK: - Private Methods

    /// 開始/停止ボタンがタップされたときの処理
    private func handleRecordingToggle() {
        // 開始時にセンサー対応をチェック
        if !viewModel.isRecording {
            let service = CoreMotionService()
            guard service.isDeviceMotionAvailable else {
                showUnavailableAlert = true
                return
            }
        }

        // 計測開始/停止をトグル
        viewModel.toggleRecording()
    }

    // MARK: - Formatter

    /// 日時のフォーマッター（時刻表示用）
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }
}

// MARK: - Preview

#Preview {
    MotionView()
}
