/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    /// Underlying central manager.
    private var centralManager: CBCentralManager!
    /// A list of discovered peripherals.
    @Published private(set) var discoveredPeripherals: [BluetoothPeripheral] = []
    /// The blinky peripheral that this manager is currently connecting or connected to.
    private var connectedPeripheral: BluetoothPeripheral?
    /// Timer for periodic scanning.
    private var scanTimer: Timer?

    var state: CBManagerState {
        return centralManager.state
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : true])
    }

    func startPeriodicScan(interval: TimeInterval = 5.0, scanDuration: TimeInterval = 2.0) {
        stopScan() // Ensure previous scan is stopped
        scanTimer?.invalidate() // Stop any existing timer

        scanTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.centralManager.state == .poweredOn else { return }
            self.startScan()
            DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) { [weak self] in
                self?.stopScan()
            }
        }
        scanTimer?.fire() // Start scanning immediately
    }

    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }

    func stopScan() {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }

    func stopPeriodicScan() {
        scanTimer?.invalidate()
        scanTimer = nil
        stopScan()
    }

    func reset() {
        discoveredPeripherals.removeAll()
    }

    var isEmpty: Bool {
        return discoveredPeripherals.isEmpty
    }

    /// Connects to the Blinky device.
    func connect(_ blinky: BluetoothPeripheral) {
        guard state == .poweredOn, connectedPeripheral == nil else { return }
        connectedPeripheral = blinky
        print("Connecting to Blinky device...")
        centralManager.connect(blinky.basePeripheral)
    }

    /// Cancels existing or pending connection.
    func disconnect(_ blinky: BluetoothPeripheral) {
        guard state == .poweredOn else { return }
        guard blinky.state != .disconnected else {
            connectedPeripheral = nil
            return
        }
        print("Cancelling connection...")
        centralManager.cancelPeripheralConnection(blinky.basePeripheral)
    }
}


extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state changed to \(central.state)")
        if central.state != .poweredOn {
            connectedPeripheral = nil
        }
        post(.manager(self, didChangeStateTo: central.state))
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if (advertisementData[CBAdvertisementDataLocalNameKey]) as? String == nil {
            return
        }
        
        let blinky = BluetoothPeripheral(
                withPeripheral: peripheral,
                advertisementData: advertisementData,
                andRSSI: RSSI,
                using: self
        )
        if !discoveredPeripherals.contains(blinky) {
            discoveredPeripherals.append(blinky)
        }
        post(.manager(self, didDiscover: blinky))
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        if let blinky = connectedPeripheral,
           blinky.basePeripheral.identifier == peripheral.identifier {
            print("Blinky connected")
            blinky.post(.blinkyDidConnect(blinky))
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        if let blinky = connectedPeripheral,
           blinky.basePeripheral.identifier == peripheral.identifier {
            if let error = error {
                print("Connection failed: \(error)")
            } else {
                print("Connection failed: No error")
            }
            connectedPeripheral = nil
            blinky.post(.blinkyDidFailToConnect(blinky, error: error))
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        if let blinky = connectedPeripheral,
           blinky.basePeripheral.identifier == peripheral.identifier {
            print("Blinky disconnected")
            connectedPeripheral = nil
            blinky.post(.blinkyDidDisconnect(blinky, error: error))
        }
    }
}
