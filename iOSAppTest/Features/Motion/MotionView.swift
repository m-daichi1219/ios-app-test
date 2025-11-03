import CoreMotion
import SwiftUI

private final class MotionPrompt {
    private let activityManager = CMMotionActivityManager()
    func request() {
        // 直近範囲のクエリで初回ダイアログ（Motionとフィットネス）を表示
        activityManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, _ in }
    }
}

struct MotionView: View {
    private let prompt = MotionPrompt()

    var body: some View {
        VStack(spacing: 12) {
            Text("Motion サンプル").font(.title3).bold()
            Text("TODO: CoreMotion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("モーションの権限をリクエスト") {
                prompt.request()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
