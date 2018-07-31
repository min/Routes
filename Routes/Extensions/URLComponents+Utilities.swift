//
//  URLComponents+Utilities.swift
//  Routes
//
//  Created by Min Kim on 7/31/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

extension URLComponents {
    func rte_queryParams() -> [String: Any] {
        var parameters: [String: Any] = [:]

        let items: [URLQueryItem] = self.queryItems ?? []

        for item in items {
            guard let value = item.value else {
                continue
            }
            if parameters[item.name] == nil {
                parameters[item.name] = value
            } else if var array = parameters[item.name] as? [Any] {
                array.append(value)
                parameters[item.name] = array
            } else {
                parameters[item.name] = [parameters[item.name], value]
            }
        }

        return parameters
    }

    static func rte_path(components: inout URLComponents, treatsHostAsPathComponent: Bool) -> String {
        if let host = components.host, !host.isEmpty && (treatsHostAsPathComponent || (host != "localhost" && host.range(of: ".") == nil)) {
            let percentEncodedHost: String = components.percentEncodedHost ?? ""
            components.host = "/"
            components.percentEncodedPath = (percentEncodedHost as NSString).appendingPathComponent(components.percentEncodedPath)
        }

        var path = components.percentEncodedPath

        if components.fragment != nil {
            var fragmentContainsQueryParams: Bool = false

            if var fragmentComponents = URLComponents(string: components.percentEncodedFragment ?? "") {

                if fragmentComponents.query == nil {
                    fragmentComponents.query = fragmentComponents.path
                }

                if let queryItems = fragmentComponents.queryItems, !queryItems.isEmpty {
                    fragmentContainsQueryParams = (queryItems.first?.value?.count ?? 0) > 0
                }

                if fragmentContainsQueryParams {
                    var queryItems: [URLQueryItem] = []
                    if let items = components.queryItems {
                        queryItems.append(contentsOf: items)
                    }
                    if let items = fragmentComponents.queryItems {
                        queryItems.append(contentsOf: items)
                    }
                    components.queryItems = queryItems
                }

                if !fragmentContainsQueryParams || fragmentComponents.path != fragmentComponents.query {
                    path += "#\(fragmentComponents.percentEncodedPath)"
                }
            }
        }

        return path
    }
}
