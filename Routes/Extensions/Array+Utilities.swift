//
//  Array+Utilities.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

extension Array {
    func route_allOrderedCombinations() -> [[Element]] {
        guard !isEmpty, let lastObject = self.last else {
            return [[]]
        }
        let subarray: [Any] = Array(self[0..<(count - 1)])
        let subarrayCombinations: [[Any]] = subarray.route_allOrderedCombinations()
        var combinations: [[Any]] = subarrayCombinations

        subarrayCombinations.forEach { combination in
            var subarrayCombos: [Any] = combination
            subarrayCombos.append(lastObject)
            combinations.append(subarrayCombos)
        }

        return (combinations as? [[Element]]) ?? []
    }
}
