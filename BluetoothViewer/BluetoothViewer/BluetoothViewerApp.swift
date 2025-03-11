//
//  BluetoothViewerApp.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import SwiftUI
import SwiftData

@main
struct BluetoothViewer: App {
    @StateObject private var bluetoothViewModel = BluetoothViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(bluetoothViewModel)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                bluetoothViewModel.startScanning()
            case .inactive, .background:
                bluetoothViewModel.stopScanning()
            @unknown default:
                break
            }
        }
    }
}
