//
//  Router.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

@dynamicMemberLookup
public class Router {
    public static let defaultScheme: String = "__scheme__"

    public private(set) lazy var `default` = routes(for: Router.defaultScheme)

    private var mapping: [String: Routes] = [:]

    public init() {}

    @discardableResult
    public func route(to resource: Resource, parameters: [String: Any] = [:]) -> Bool {
        let routes: Routes = self.routes(for: resource)

        var didRoute: Bool = routes.route(resource: resource, parameters: parameters)

        if !didRoute && routes.shouldFallback && routes !== `default` {
            didRoute = `default`.route(resource: resource, parameters: parameters)
        }

        return didRoute
    }

    public func canRoute(to resource: Resource) -> Bool {
        let routes: Routes = self.routes(for: resource)

        var didRoute: Bool = routes.canRoute(resource: resource)

        if !didRoute && routes.shouldFallback && routes !== `default` {
            didRoute = `default`.canRoute(resource: resource)
        }

        return didRoute
    }

    public subscript(scheme: String) -> Routes {
        get {
            return routes(for: scheme)
        }
        set {}
    }

    public subscript(dynamicMember member: String) -> Routes {
        return self[member]
    }

    public func routes(for resource: Resource) -> Routes {
        guard let scheme = resource.url?.scheme else {
            return self.default
        }
        return mapping[scheme, default: self.default]
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

    var definitionMapping: [String: [Definition]] {
        var result: [String: [Definition]] = [:]

        mapping.forEach { mapping in
            result[mapping.key] = mapping.value.definitions
        }

        return result
    }
}
