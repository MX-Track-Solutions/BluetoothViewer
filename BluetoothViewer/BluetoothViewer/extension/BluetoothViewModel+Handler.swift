//
//  BluetoothViewModel+Handler.swift
//  BluetoothViewer
//
//  Created by Bram on 12/03/2025.
//

import CoreBluetooth

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Auto-start scanning
            startScanning()
        } else {
            // Clear out any known devices
            peripherals.removeAll()
            discoveredPeripherals.removeAll()
            lastUpdateTime.removeAll()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        var measuredRSSI = RSSI.intValue

        // Filter out impossible (positive) RSSI
        if measuredRSSI > 0 {
            measuredRSSI = 0
        }

        // Respect threshold
        guard measuredRSSI >= rssiThreshold else { return }

        // Check device name from advertisement
        let localName =
            advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let deviceName = peripheral.name ?? localName
        guard deviceName != nil else {
            // Skip if there's no name at all (remove this if you want unnamed)
            return
        }

        let now = Date()

        // Throttle updates
        if let lastUpdate = lastUpdateTime[peripheral.identifier],
            now.timeIntervalSince(lastUpdate) < minUpdateInterval
        {
            return
        }

        // RSSI smoothing
        if let existing = discoveredPeripherals[peripheral.identifier] {
            let oldRSSI = existing.rssi.intValue
            let averaged = (oldRSSI + measuredRSSI) / 2
            discoveredPeripherals[peripheral.identifier] = (
                peripheral,
                NSNumber(value: averaged),
                now
            )
        } else {
            discoveredPeripherals[peripheral.identifier] = (
                peripheral,
                NSNumber(value: measuredRSSI),
                now
            )
        }

        lastUpdateTime[peripheral.identifier] = now

        // Refresh the published list
        cleanupOldDevices()
    }
}
