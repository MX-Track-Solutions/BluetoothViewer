//
//  PeripheralDetailView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import SwiftUI
import CoreBluetooth

struct PeripheralDetailView: View {
    @EnvironmentObject var bluetoothViewModel: BluetoothViewModel
    let peripheral: CBPeripheral

    var body: some View {
        VStack(spacing: 20) {
            Text(peripheral.name ?? "Unknown Device")
                .font(.largeTitle)
                .padding()

            // More device info
            Text("Identifier: \(peripheral.identifier.uuidString)")
                .foregroundColor(.secondary)

            // Connect button
            Button(action: {
                //bluetoothViewModel.connect(peripheral: peripheral)
            }) {
                Text("Connect")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            // Text(bluetoothViewModel.connectionState(for: peripheral))
            //     .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
