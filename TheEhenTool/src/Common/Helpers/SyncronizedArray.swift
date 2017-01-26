//
//  SyncronizedArray.swift
//  TheEhenTool
//
//  Credit to rmooney on stackoverflow.com
//
//  CMonk on 1/19/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation

public class SynchronizedArray<T> {
    internal var array: [T] = []
    internal let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)
    
    public func append(newElement: T) {
        
        self.accessQueue.sync(flags:.barrier) {
            self.array.append(newElement)
        }
    }
    
    public func remove(at index: Int) -> T {
        return self.accessQueue.sync(flags:.barrier) {
            self.array.remove(at: index)
        }
    }
    
    public var count: Int {
        return self.accessQueue.sync(flags:.barrier) {
            self.array.count
        }
    }
    
    public func first() -> T? {
        return self.accessQueue.sync(flags:.barrier) {
            if !self.array.isEmpty {
                return self.array[0]
            }
            return nil
        }
    }
    
    public subscript(index: Int) -> T {
        set {
            self.accessQueue.sync(flags:.barrier) {
                self.array[index] = newValue
            }
        }
        get {
            return self.accessQueue.sync(flags:.barrier) {
                self.array[index]
            }
        }
    }
}

extension SynchronizedArray: Sequence {
    public typealias Iterator = Array<T>.Iterator
    public typealias SubSequence = Array<T>.SubSequence
    
    public var underestimatedCount: Int {
        return self.accessQueue.sync(flags:.barrier) {
            array.underestimatedCount
        }
    }

    public func dropFirst(_ n: Int) -> ArraySlice<T> {
        return self.accessQueue.sync(flags:.barrier) {
            array.dropFirst(n)
        }
    }

    public func dropLast(_ n: Int) -> ArraySlice<T> {
        return self.accessQueue.sync(flags:.barrier) {
            array.dropLast(n)
        }
    }

    public func filter(_ isIncluded: (T) throws -> Bool) rethrows -> [T] {
        return try self.accessQueue.sync(flags:.barrier) {
            try array.filter(isIncluded)
        }
    }
    
    public func forEach(_ body: (T) throws -> Void) rethrows {
        return try self.accessQueue.sync(flags:.barrier) {
            try array.forEach(body)
        }
    }
    
    public func makeIterator() -> IndexingIterator<Array<T>> {
        return self.accessQueue.sync(flags:.barrier) {
            array.makeIterator()
        }
    }
    
    public func map(_ transform: (T) throws -> T) rethrows -> [T] {
        return try self.accessQueue.sync(flags:.barrier) {
            try array.map(transform)
        }
    }
    
    public func prefix(_ maxLength: Int) -> ArraySlice<T> {
        return self.accessQueue.sync(flags:.barrier) {
            array.prefix(maxLength)
        }
    }
    
    public func split(maxSplits: Int, omittingEmptySubsequences: Bool, whereSeparator isSeparator: (T) throws -> Bool) rethrows -> [ArraySlice<T>] {
        return try self.accessQueue.sync(flags:.barrier) {
            try array.split(maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences, whereSeparator: isSeparator)
        }
    }
    
    public func suffix(_ maxLength: Int) -> ArraySlice<T> {
        return self.accessQueue.sync(flags:.barrier) {
            array.suffix(maxLength)
        }
    }
    
}
