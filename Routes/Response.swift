//
//  Response.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

struct Response: Equatable {
    static func == (lhs: Response, rhs: Response) -> Bool {
        return lhs.isMatch == rhs.isMatch &&
            lhs.parameters.keys.sorted() == rhs.parameters.keys.sorted()
    }

    let isMatch: Bool
    let parameters: [String: Any]

    static var invalid: Response {
        return Response(isMatch: false, parameters: [:])
    }
}
