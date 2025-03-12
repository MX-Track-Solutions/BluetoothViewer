//
//  BluetoothViewModel.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import CoreBluetooth
import SwiftUI

class BluetoothViewModel: NSObject, ObservableObject {
    public var centralManager: CBCentralManager?
    private var isScanning = false

    // Published list of (Peripheral, RSSI) for display
    @Published var peripherals: [(peripheral: CBPeripheral, rssi: NSNumber)] = []
    @Published var connectedPeripheral: CBPeripheral? = nil

    // Dictionary to track discovered peripherals
    public var discoveredPeripherals: [UUID: (peripheral: CBPeripheral, rssi: NSNumber, lastSeen: Date)] = [:]

    // Track last update time to throttle UI updates
    public var lastUpdateTime: [UUID: Date] = [:]

    // Configuration
    public let rssiThreshold: Int = -70  // Only show devices >= -70 dBm
    private let timeoutDuration: TimeInterval = 6.0
    public let minUpdateInterval: TimeInterval = 1.0
    private let scanRestartInterval: TimeInterval = 10.0

    private var scanTimer: Timer?
    private var cleanupTimer: Timer?

    // MARK: - Lifecycle
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scanning
    func startScanning() {
        guard let central = centralManager,
            central.state == .poweredOn,
            !isScanning
        else { return }

        print("Starting Bluetooth Scan...")
        isScanning = true
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanRestartInterval, repeats: true) { _ in
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

    func stopScanning() {
        guard isScanning else { return }

        print("Stopping Bluetooth Scan...")
        isScanning = false
        centralManager?.stopScan()
        scanTimer?.invalidate()
        cleanupTimer?.invalidate()
    }

    private func restartScanning() {
        guard let central = centralManager, central.state == .poweredOn else {
            return
        }

        central.stopScan()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            central.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }

    public func cleanupOldDevices() {
        let now = Date()

        // Filter out devices not seen within `timeoutDuration`, unless they are connected
        discoveredPeripherals = discoveredPeripherals.filter { _, value in
            let isConnected = value.peripheral.state == .connected
            return isConnected || now.timeIntervalSince(value.lastSeen) < timeoutDuration
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
    }
}
