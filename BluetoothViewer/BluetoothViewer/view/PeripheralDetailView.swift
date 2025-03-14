//
//  PeripheralDetailView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftUI

struct PeripheralDetailView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let peripheral: BluetoothPeripheral
    
    private var isConnected: Bool {
        peripheral.state == .connected
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(peripheral.advertisedName)
                .font(.largeTitle)
                .padding()

            // More device info
            Text("Identifier: \(peripheral.basePeripheral.identifier.uuidString)")
                .foregroundColor(.secondary)

            // MARK: - Connect/Disconnect Button
            Button(action: {
                if peripheral.isConnected {
                    bluetoothManager.disconnect(peripheral)
                } else {
                    bluetoothManager.connect(peripheral)
                }
            }) {
                Text(isConnected ? "Disconnect" : "Connect")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(isConnected ? Color.red : Color.blue)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
