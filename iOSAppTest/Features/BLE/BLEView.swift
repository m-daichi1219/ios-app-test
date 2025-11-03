import CoreBluetooth
import SwiftUI

private final class BLEPrompt: NSObject, CBCentralManagerDelegate {
    private var central: CBCentralManager?
    func request() {
        central = CBCentralManager(delegate: self, queue: nil)
        // stateがpoweredOnになったらスキャン開始 → 初回にBluetoothの許可ダイアログ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.central?.scanForPeripherals(withServices: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.central?.stopScan()
            }
        }
    }

    func centralManagerDidUpdateState(_: CBCentralManager) {}
}

struct BLEView: View {
    private let prompt = BLEPrompt()

    var body: some View {
        VStack(spacing: 12) {
            Text("BLE サンプル").font(.title3).bold()
            Text("TODO: CoreBluetooth")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Bluetoothの権限をリクエスト") {
                prompt.request()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.systemBackground))
    }
}
