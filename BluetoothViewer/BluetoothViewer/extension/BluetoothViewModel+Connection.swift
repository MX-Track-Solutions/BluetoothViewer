//
//  BluetoothViewModel+Connection.swift
//  BluetoothViewer
//
//  Created by Bram on 12/03/2025.
//

import CoreBluetooth

extension BluetoothViewModel {
    
    // MARK: - Connect
    func connect(peripheral: CBPeripheral) {
        guard let central = centralManager else { return }
        
        // Avoid re-connecting if it's already connected
        if peripheral.state != .connected {
            central.connect(peripheral, options: nil)
        }
    }
    
    // MARK: - Disconnect
    func disconnect(peripheral: CBPeripheral) {
        guard let central = centralManager else { return }
        
        // Only disconnect if it's currently connected
        if peripheral.state == .connected {
            central.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - Connection Delegate Methods
extension BluetoothViewModel {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Successfully connected to \(peripheral.name ?? "Unknown")")
        
        // Update published property
        connectedPeripheral = peripheral
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("❌ Failed to connect to \(peripheral.name ?? "Unknown"): \(error.localizedDescription)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("❌ Disconnected from \(peripheral.name ?? "Unknown") with error: \(error.localizedDescription)")
        } else {
            print("❎ Disconnected from \(peripheral.name ?? "Unknown")")
        }
        
        // If the disconnected peripheral was our "connectedPeripheral", reset it
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothViewModel: CBPeripheralDelegate {
     func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
         if let error = error {
             print("Error discovering services: \(error.localizedDescription)")
             return
         }
         if let services = peripheral.services {
             for service in services {
                 peripheral.discoverCharacteristics(nil, for: service)
             }
         }
     }
    
     func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
         if let error = error {
             print("Error discovering characteristics: \(error.localizedDescription)")
             return
         }
     }
}
