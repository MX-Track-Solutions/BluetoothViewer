//
//  PeripheralDetailView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import SwiftUI
import CoreBluetooth

struct PeripheralDetailView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let peripheral: BluetoothPeripheral
    
    // A local array of log messages.
    @State private var logs: [String] = []
    // Keep references to our observers so we can remove them later.
    @State private var observers: [NSObjectProtocol] = []
    
    private var isConnected: Bool {
        peripheral.state == .connected
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(peripheral.advertisedName)
                .font(.largeTitle)
                .padding()

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
            
            // MARK: - Logs
            Text("Logs")
                .font(.headline)
            ScrollView {
                ForEach(logs, id: \.self) { logEntry in
                    Text(logEntry)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxHeight: 200) // Adjust as needed
            
        }
        .padding()
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addObservers()
        }
        .onDisappear {
            removeObservers()
        }
    }
}

// MARK: - Notification Observing
extension PeripheralDetailView {
    private func addObservers() {
        // 1. When the peripheral connects
        let connectionObserver = NotificationCenter.default.addObserver(
            forName: .connection,
            object: peripheral,
            queue: .main
        ) { _ in
            logs.append("[\(timestamp())] \(peripheral.advertisedName) connected.")
        }
        observers.append(connectionObserver)
        
        // 2. When the peripheral becomes ready (LED and button support discovered)
        let readyObserver = NotificationCenter.default.addObserver(
            forName: .ready,
            object: peripheral,
            queue: .main
        ) { notification in
            let ledSupported = notification.userInfo?["ledSupported"] as? Bool ?? false
            let buttonSupported = notification.userInfo?["buttonSupported"] as? Bool ?? false
            logs.append("[\(timestamp())] \(peripheral.advertisedName) is ready.")
            logs.append("   LED supported: \(ledSupported), Button supported: \(buttonSupported)")
        }
        observers.append(readyObserver)

        // 3. If connection fails
        let failObserver = NotificationCenter.default.addObserver(
            forName: .fail,
            object: peripheral,
            queue: .main
        ) { notification in
            let error = notification.userInfo?["error"] as? Error
            logs.append("[\(timestamp())] Connection to \(peripheral.advertisedName) failed. Error: \(error?.localizedDescription ?? "Unknown error")")
        }
        observers.append(failObserver)
        
        // 4. When the peripheral disconnects
        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .disconnection,
            object: peripheral,
            queue: .main
        ) { notification in
            let error = notification.userInfo?["error"] as? Error
            logs.append("[\(timestamp())] Disconnected from \(peripheral.advertisedName). Error: \(error?.localizedDescription ?? "None")")
        }
        observers.append(disconnectObserver)
        
        // 5. When the LED state changes
        let ledObserver = NotificationCenter.default.addObserver(
            forName: .ledState,
            object: peripheral,
            queue: .main
        ) { notification in
            if let isOn = notification.userInfo?["isOn"] as? Bool {
                logs.append("[\(timestamp())] LED changed to \(isOn ? "ON" : "OFF")")
            }
        }
        observers.append(ledObserver)
        
        // 6. When the button state changes
        let buttonObserver = NotificationCenter.default.addObserver(
            forName: .buttonState,
            object: peripheral,
            queue: .main
        ) { notification in
            if let isPressed = notification.userInfo?["isPressed"] as? Bool {
                logs.append("[\(timestamp())] Button is now \(isPressed ? "PRESSED" : "RELEASED")")
            }
        }
        observers.append(buttonObserver)
    }
    
    private func removeObservers() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
