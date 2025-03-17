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
    @StateObject private var bluetoothManager = BluetoothManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(bluetoothManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                bluetoothManager.startPeriodicScan();
            case .inactive, .background:
                bluetoothManager.stopPeriodicScan()
            @unknown default:
                break
            }
        }
    }
}
