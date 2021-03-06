//
//  File.swift
//  
//
//  Created by Dave DeLong on 10/5/19.
//

import Foundation

public struct AbsoluteValueSequence<U: Unit>: Sequence {
    
    private let constructor: () -> AbsoluteValueIterator<U>
    
    public init<S>(range: Range<Absolute<S>>, stride: Delta<U, Era>) {
        let lower = range.lowerBound
        let upper = range.upperBound.converting(to: lower.region)
        constructor = { AbsoluteValueIterator(region: lower.region, range: lower.firstInstant ..< upper.firstInstant, stride: stride) }
    }
    
    public init<S>(range: ClosedRange<Absolute<S>>, stride: Delta<U, Era>) {
        let lower = range.lowerBound
        let upper = range.upperBound.converting(to: lower.region)
        constructor = { AbsoluteValueIterator(region: lower.region, range: lower.firstInstant ... upper.firstInstant, stride: stride) }
    }
    
    internal init<S>(parent: Absolute<S>, stride: Delta<U, Era> = Delta(value: 1, unit: U.component)) {
        constructor = { AbsoluteValueIterator(region: parent.region, range: parent.range, stride: stride) }
    }
    
    public __consuming func makeIterator() -> AbsoluteValueIterator<U> {
        return constructor()
    }
    
}

public struct AbsoluteValueIterator<U: Unit>: IteratorProtocol {
    private let region: Region
    
    private let keepGoing: (Absolute<U>) -> Bool
    private let start: Absolute<U>
    
    private var scale = 0
    private let stride: DateComponents
    
    public init(region: Region, range: Range<Instant>, stride: Delta<U, Era>) {
        self.region = region
        self.keepGoing = {
            let thisRange = $0.range
            return range.lowerBound <= thisRange.lowerBound && thisRange.upperBound <= range.upperBound
        }
        self.start = Absolute<U>(region: region, instant: range.lowerBound)
        self.stride = stride.dateComponents
    }
    
    public init(region: Region, range: ClosedRange<Instant>, stride: Delta<U, Era>) {
        self.region = region
        self.keepGoing = { range.overlaps($0.range) }
        self.start = Absolute<U>(region: region, instant: range.lowerBound)
        self.stride = stride.dateComponents
    }
    
    public mutating func next() -> Absolute<U>? {
        let next = stride.scale(by: scale)
        scale += 1
        
        let delta = Delta<U, Era>(next)
        let n = start + delta
        guard keepGoing(n) else { return nil }
        
        return n
    }
}
