//
//  Dictionary+Utilities.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    func route_queryParams(decodePlusSymbols: Bool) -> Dictionary {
        guard decodePlusSymbols else {
            return self
        }

        var queryParams: [Key: Value] = [:]

        forEach { key, value in
            if let array = value as? NSArray {
                let variables: [String] = array
                    .compactMap({ $0 as? String })
                    .map({ $0.route_variableValue(decodePlusSymbols: decodePlusSymbols) })

                queryParams[key] = variables
            } else if let string = value as? String {
                queryParams[key] = string.route_variableValue(decodePlusSymbols: decodePlusSymbols)
            } else {
                assert(false, "Unexpected query parameter type: \(type(of: value))")
            }
        }

        return queryParams
    }
}
