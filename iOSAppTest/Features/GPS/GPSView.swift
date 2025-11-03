import CoreLocation
import SwiftUI

struct GPSView: View {
    // MARK: - Properties

    /// ViewModel を View が所有（@StateObject）
    /// View が生成されるときに一度だけ初期化され、View が破棄されるまで生き続ける
    @StateObject private var viewModel = GPSViewModel(
        locationService: CoreLocationService() // 本番実装を注入
    )

    /// 権限拒否アラートの表示状態
    @State private var showDeniedAlert = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // タイトル
            Text("GPS 計測")
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
            List(viewModel.displayLocations) { data in
                VStack(alignment: .leading, spacing: 4) {
                    Text("緯度: \(data.latitude, specifier: "%.6f")")
                    Text("経度: \(data.longitude, specifier: "%.6f")")
                    Text("高度: \(data.altitude, specifier: "%.1f") m")
                    Text("精度: \(data.horizontalAccuracy, specifier: "%.1f") m")
                    Text("時刻: \(data.timestamp, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            .listStyle(.plain)

            Spacer()
        }
        .padding()
        .alert("位置情報が許可されていません", isPresented: $showDeniedAlert) {
            Button("設定を開く") { AppSettings.open() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定 > プライバシーとセキュリティ > 位置情報 で許可に変更してください")
        }
    }

    // MARK: - Private Methods

    /// 開始/停止ボタンがタップされたときの処理
    private func handleRecordingToggle() {
        // 計測開始前に権限をチェック
        if !viewModel.isRecording {
            let service = CoreLocationService() // 一時的にインスタンス生成して権限確認
            let status = service.authorizationStatus

            if status == .notDetermined {
                // 初回：権限リクエストを出す
                service.requestWhenInUseAuthorization()
                // リクエスト後、ユーザーが許可したら次回タップで開始できる
                return
            } else if status == .denied || status == .restricted {
                // 拒否済み：設定画面へ誘導
                showDeniedAlert = true
                return
            }
        }

        // 権限OK：計測開始/停止をトグル
        viewModel.toggleRecording()
    }

    // MARK: - Formatter

    /// 日時のフォーマッター（時刻表示用）
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
}

// MARK: - Preview

#Preview {
    GPSView()
}
