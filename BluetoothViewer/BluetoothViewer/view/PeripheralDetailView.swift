//
//  PeripheralDetailView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftUI

struct PeripheralDetailView: View {
    @EnvironmentObject var bluetoothViewModel: BluetoothViewModel
    let peripheral: CBPeripheral
    
    private var isConnected: Bool {
            peripheral.state == .connected
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(peripheral.name ?? "Unknown Device")
                .font(.largeTitle)
                .padding()

            // More device info
            Text("Identifier: \(peripheral.identifier.uuidString)")
                .foregroundColor(.secondary)

            // MARK: - Connect/Disconnect Button
            Button(action: {
                if isConnected {
                    bluetoothViewModel.disconnect(peripheral: peripheral)
                } else {
                    bluetoothViewModel.connect(peripheral: peripheral)
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
