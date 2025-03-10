//
//  Collection+Extension.swift
//  TAKAware
//
//  Created by Cory Foy on 3/9/25.
//  Adapted from https://stackoverflow.com/a/28035219

extension Collection {
    func unfoldSubSequences(limitedTo maxLength: Int) -> UnfoldSequence<SubSequence,Index> {
        sequence(state: startIndex) { start in
            guard start < self.endIndex else { return nil }
            let end = self.index(start, offsetBy: maxLength, limitedBy: self.endIndex) ?? self.endIndex
            defer { start = end }
            return self[start..<end]
        }
    }
}
