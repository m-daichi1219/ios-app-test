import Foundation

enum MenuItem: CaseIterable, Identifiable {
    case home
    case ble
    case gps
    case motion

    var id: Self { self }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .ble:
            return "BLE"
        case .gps:
            return "GPS"
        case .motion:
            return "Motion"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .ble: return "dot.radiowaves.left.and.right"
        case .gps: return "location"
        case .motion: return "gyroscope"
        }
    }
}
