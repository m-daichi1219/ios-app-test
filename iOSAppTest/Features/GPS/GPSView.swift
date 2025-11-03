import CoreLocation
import SwiftUI

// TODO: すでに許可済みのケース
private final class LocationPrompt: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    func request() {
        manager.delegate = self
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // View側でアラートを出すことを想定
            break
        default:
            manager.startUpdatingLocation()
        }
    }
}

struct GPSView: View {
    private let prompt = LocationPrompt()
    @State private var showDeniedAlert: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Text("GPS サンプル").font(.title3).bold()
            Text("TODO: CoreLocation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("位置情報の権限を確認/要求") {
                let status = CLLocationManager.authorizationStatus()
                if status == .denied || status == .restricted {
                    showDeniedAlert = true
                } else {
                    prompt.request()
                }
            }
        }
        .alert("位置情報が許可されていません", isPresented: $showDeniedAlert) {
            Button("設定を開く") { AppSettings.open() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定 > アプリ > 位置情報 で許可に変更してください")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
