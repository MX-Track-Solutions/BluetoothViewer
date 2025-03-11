//
//  PeripheralRow.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftUICore

struct PeripheralRow: View {
    let peripheral: CBPeripheral
    let rssi: NSNumber

    var body: some View {
        let strength = rssi.intValue.signalStrength

        HStack(spacing: 15) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(strength.color)

            // Device info
            VStack(alignment: .leading, spacing: 4) {
                Text(peripheral.name ?? "Unknown Device")
                    .font(.headline)
                Text("Signal: \(rssi.intValue) dBm")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            // Bars
            SignalStrengthView(rssi: rssi.intValue)
        }
        .padding(.vertical, 8)
    }
}
