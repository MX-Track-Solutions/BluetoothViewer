//
//  BluetoothViewModel.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftUI

class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?

    // Published list of (Peripheral, RSSI) for display
    @Published var peripherals: [(peripheral: CBPeripheral, rssi: NSNumber)] =
        []

    // Dictionary to track discovered peripherals
    private var discoveredPeripherals:
        [UUID: (peripheral: CBPeripheral, rssi: NSNumber, lastSeen: Date)] = [:]

    // Track last update time to throttle UI updates
    private var lastUpdateTime: [UUID: Date] = [:]

    // Configuration
    private let rssiThreshold: Int = -70  // Only show devices >= -70 dBm
    private let timeoutDuration: TimeInterval = 6.0
    private let minUpdateInterval: TimeInterval = 1.0
    private let scanRestartInterval: TimeInterval = 10.0

    private var scanTimer: Timer?
    private var cleanupTimer: Timer?

    // MARK: - Lifecycle
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scanning
    private func startScanning() {
        guard let central = centralManager,
            central.state == .poweredOn
        else { return }

        print("Starting Bluetooth Scan...")
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(
            withTimeInterval: scanRestartInterval, repeats: true
        ) { _ in
            self.restartScanning()
        }

        // Cleanup on a timer
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: 5.0, repeats: true
        ) { _ in
            self.cleanupOldDevices()
        }
    }

    private func restartScanning() {
        guard let central = centralManager, central.state == .poweredOn else {
            return
        }
        print("Restarting Bluetooth Scan...")

        central.stopScan()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            central.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }

    private func cleanupOldDevices() {
        let now = Date()

        // Filter out devices not seen within `timeoutDuration`
        discoveredPeripherals = discoveredPeripherals.filter { _, value in
            now.timeIntervalSince(value.lastSeen) < timeoutDuration
        }

        // Preserve old order while rebuilding the list
        let oldOrder = peripherals.map { $0.peripheral.identifier }

        peripherals = oldOrder.compactMap { id in
            guard let entry = discoveredPeripherals[id] else { return nil }
            return (entry.peripheral, entry.rssi)
        }

        // Add newly discovered devices not in the old order
        let newKeys = Set(discoveredPeripherals.keys).subtracting(oldOrder)
        for newId in newKeys {
            if let newEntry = discoveredPeripherals[newId] {
                peripherals.append((newEntry.peripheral, newEntry.rssi))
            }
        }

        // Debugging
        print("Cleanup: \(peripherals.count) devices remain")
    }
}

// MARK: - CBCentralManagerDelegate
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
