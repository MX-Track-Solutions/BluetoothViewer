//
//  ContentView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var bluetoothManager: BluetoothManager

    var body: some View {
        NavigationView {
            List {
                ForEach(bluetoothManager.discoveredPeripherals, id: \.basePeripheral.identifier) { item in
                    NavigationLink(
                        destination: PeripheralDetailView(peripheral: item).environmentObject(bluetoothManager)
                    ) {
                        PeripheralRow(peripheral: item)
                    }
                }

            }
            .navigationTitle("Nearby Devices")
            .listStyle(PlainListStyle())
        }
    }
}

#Preview {
    ContentView().environmentObject(BluetoothManager())
}
