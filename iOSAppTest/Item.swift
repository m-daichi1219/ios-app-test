//
//  Item.swift
//  iOSAppTest
//
//  Created by daichi on 2025/10/19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
