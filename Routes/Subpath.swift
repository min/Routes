//
//  Subpath.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

struct Subpath: Equatable, Hashable {
    let subpathComponents: [String]
    let isOptionalSubpath: Bool

    var hashValue: Int {
        return subpathComponents.reduce(isOptionalSubpath.hashValue) { $0 ^ $1.hashValue }
    }
}
