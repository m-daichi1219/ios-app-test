import SwiftUI

struct GPSView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("GPS サンプル").font(.title3).bold()
            Text("TODO: CoreLocation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
