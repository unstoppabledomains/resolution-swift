//
//  Utilities.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class Utillities {
    static func isNotEmpty(_ value: String) -> Bool {
        let nullValues = [
        "0x",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000000"
        ]
        return !(value.isEmpty || nullValues.contains(value))
    }
}
