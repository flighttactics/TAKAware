//
//  StringProtocol+Extension.swift
//  TAKAware
//
//  Created by Cory Foy on 3/9/25.
//  Adapted from https://stackoverflow.com/a/28035219

import Foundation

extension StringProtocol {
    var byte: UInt8? { UInt8(self, radix: 16) }
    var hexaToBytes: [UInt8] { unfoldSubSequences(limitedTo: 2).compactMap(\.byte) }
    var hexaToData: Data { .init(hexaToBytes) }
}
