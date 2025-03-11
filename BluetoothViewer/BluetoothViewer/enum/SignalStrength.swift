//
//  SignalStrength.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import SwiftUICore

/// Represents signal strength tiers based on RSSI.
enum SignalStrength {
    case excellent  // 5 bars
    case good  // 4 bars
    case fair  // 3 bars
    case weak  // 2 bars

    /// Initialize using an RSSI value in dBm.
    init(rssi: Int) {
        switch rssi {
        case -55...0:
            self = .excellent
        case -65 ... -56:
            self = .good
        case -70 ... -66:
            self = .fair
        default:
            self = .weak
        }
    }

    /// The number of "bars" (2–5) to display for this strength.
    var bars: Int {
        switch self {
        case .excellent: return 5
        case .good: return 4
        case .fair: return 3
        case .weak: return 2
        }
    }

    /// Color associated with this strength tier.
    var color: Color {
        switch self {
        case .excellent, .good: return .green
        case .fair: return .orange
        case .weak: return .red
        }
    }
}

// MARK: - Int Extension

extension Int {
    /// Interpret an RSSI (dBm) value as a `SignalStrength`.
    var signalStrength: SignalStrength {
        SignalStrength(rssi: self)
    }
}
