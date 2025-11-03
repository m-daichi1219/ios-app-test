import CoreLocation
import SwiftUI

private final class LocationPrompt: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    func request() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
}

struct GPSView: View {
    private let prompt = LocationPrompt()
    var body: some View {
        VStack(spacing: 12) {
            Text("GPS サンプル").font(.title3).bold()
            Text("TODO: CoreLocation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("位置情報の権限をリクエスト") {
                prompt.request()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
