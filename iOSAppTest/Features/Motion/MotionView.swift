import SwiftUI

struct MotionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Motion サンプル").font(.title3).bold()
            Text("TODO: CoreMotion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
