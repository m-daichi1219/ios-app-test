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
    @State private var showDeniedAlert = false
    private let prompt = MotionPrompt()

    var body: some View {
        VStack(spacing: 12) {
            Text("Motion サンプル").font(.title3).bold()
            Text("TODO: CoreMotion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("モーションを確認/要求") {
                let status = CMMotionActivityManager.authorizationStatus()
                if status == .denied || status == .restricted {
                    showDeniedAlert = true
                } else {
                    prompt.request()
                }
            }
            // ...existing code...
        }
        .alert("モーションが許可されていません", isPresented: $showDeniedAlert) {
            Button("設定を開く") { AppSettings.open() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定 > プライバシーとセキュリティ > モーションとフィットネス で許可に変更してください。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
