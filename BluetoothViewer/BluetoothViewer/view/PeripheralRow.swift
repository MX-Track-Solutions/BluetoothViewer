//
//  PeripheralRow.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftUICore

struct PeripheralRow: View {
    let peripheral: BluetoothPeripheral

    var body: some View {
        let strength = peripheral.RSSI.signalStrength

        HStack(spacing: 15) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(strength.color)

            // Device info
            VStack(alignment: .leading, spacing: 4) {
                Text(peripheral.advertisedName)
                    .font(.headline)
                Text("Signal: \(peripheral.RSSI.intValue) dBm")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            // Bars
            SignalStrengthView(rssi: peripheral.RSSI)
        }
        .padding(.vertical, 8)
    }
}
