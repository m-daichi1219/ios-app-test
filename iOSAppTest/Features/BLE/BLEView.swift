import SwiftUI

struct BLEView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("BLE サンプル").font(.title3).bold()
            Text("TODO: CoreBluetooth")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
