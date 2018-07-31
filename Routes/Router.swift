//
//  Router.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

public class Router {
    public static let defaultScheme: String = "__scheme__"

    public private(set) lazy var `default` = routes(for: Router.defaultScheme)

    private var mapping: [String: Routes] = [:]

    public init() {}

    public func route(url: URL, parameters: [String: Any]) -> Bool {
        let routes: Routes = self.routes(for: url)

        var didRoute: Bool = routes.route(url: url, parameters: parameters)

        if !didRoute && routes.shouldFallback && routes !== `default` {
            didRoute = `default`.route(url: url, parameters: parameters)
        }

        return didRoute
    }

    public func canRoute(url: URL) -> Bool {
        let routes: Routes = self.routes(for: url)

        var didRoute: Bool = routes.canRoute(url: url)

        if !didRoute && routes.shouldFallback && routes !== `default` {
            didRoute = `default`.canRoute(url: url)
        }

        return didRoute
    }

    public subscript(scheme: String) -> Routes {
        get {
            return routes(for: scheme)
        }
    }

    public func routes(for url: URL) -> Routes {
        guard let scheme = url.scheme else {
            return self.default
        }
        return mapping[scheme] ?? self.default
    }

    /// Returns a routing namespace for the given scheme
    public func routes(for scheme: String) -> Routes {
        if let routes = mapping[scheme] {
            return routes
        } else {
            let routes = Routes(scheme: scheme)
            mapping[scheme] = routes
            return routes
        }
    }

    public func unregister(scheme: String) {
        _ = mapping.removeValue(forKey: scheme)
    }

    public func unregisterAll() {
        mapping.removeAll()
    }

    public var definitionMapping: [String: [Definition]] {
        var result: [String: [Definition]] = [:]

        mapping.forEach({
            result[$0.key] = $0.value.definitions
        })

        return result
    }
}
