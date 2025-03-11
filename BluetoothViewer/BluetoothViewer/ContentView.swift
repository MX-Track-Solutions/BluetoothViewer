//
//  ContentView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import SwiftUI
import SwiftData
import CoreBluetooth

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedPeripherals(), id: \.peripheral.identifier) { item in
                    PeripheralRow(peripheral: item.peripheral, rssi: item.rssi)
                }
            }
            .navigationTitle("Nearby Devices")
            .listStyle(PlainListStyle())
        }
    }
    
    /// Sort by number of bars first (descending), then RSSI (less negative is stronger).
    private func sortedPeripherals() -> [(peripheral: CBPeripheral, rssi: NSNumber)] {
        bluetoothViewModel.peripherals.sorted { lhs, rhs in
            let lhsBars = lhs.rssi.intValue.signalStrength.bars
            let rhsBars = rhs.rssi.intValue.signalStrength.bars
            
            if lhsBars != rhsBars {
                return lhsBars > rhsBars
            } else {
                // If the "bars" tie, fall back to the raw RSSI (larger == stronger).
                return lhs.rssi.intValue > rhs.rssi.intValue
            }
        }
    }
}

#Preview {
    ContentView()
}
