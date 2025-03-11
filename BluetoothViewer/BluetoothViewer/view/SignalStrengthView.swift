//
//  SignalStrengthView.swift
//  BluetoothViewer
//
//  Created by Bram on 11/03/2025.
//

import SwiftUICore

struct SignalStrengthView: View {
    let rssi: Int
    
    private var strength: SignalStrength {
        rssi.signalStrength
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Rectangle()
                    .fill(level <= strength.bars ? strength.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: CGFloat(level * 5))
                    .cornerRadius(2)
            }
        }
        .frame(height: 30)
    }
}
