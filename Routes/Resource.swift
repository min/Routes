//
//  Resource.swift
//  Routes
//
//  Created by Min Kim on 8/2/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

public protocol Resource {
    var url: URL? { get }
}

extension URL: Resource {
    public var url: URL? {
        return self
    }
}

extension String: Resource {
    public var url: URL? {
        return URL(string: self)
    }
}
