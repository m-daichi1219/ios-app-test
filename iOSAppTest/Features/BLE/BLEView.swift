import CoreBluetooth
import SwiftUI

// TODO: すでに許可済みのケース
private final class BLEPrompt: NSObject, CBCentralManagerDelegate {
    private var central: CBCentralManager?
    func start() {
        central = CBCentralManager(delegate: self, queue: nil)
        // poweredOn後にスキャン開始（初回はここで権限の確認）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.central?.scanForPeripherals(withServices: nil)
        }
    }

    func centralManagerDidUpdateState(_: CBCentralManager) {}
}

struct BLEView: View {
    @State private var showDeniedAlert = false
    private let prompt = BLEPrompt()

    var body: some View {
        VStack(spacing: 12) {
            Text("BLE サンプル").font(.title3).bold()
            Text("TODO: CoreBluetooth")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Bluetoothを確認/開始") {
                let auth = CBManager.authorization
                if auth == .denied || auth == .restricted {
                    showDeniedAlert = true
                } else {
                    prompt.start()
                }
            }
        }
        .alert("Bluetoothが許可されていません", isPresented: $showDeniedAlert) {
            Button("設定を開く") { AppSettings.open() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定 > プライバシーとセキュリティ > Bluetooth で許可に変更してください。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
