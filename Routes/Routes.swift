//
//  Routes.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

public struct Options: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let decodePlusSymbols: Options = .init(rawValue: 1 << 0)
    public static let treatHostAsPathComponent: Options = .init(rawValue: 1 << 1)
}

public class Routes {
    public typealias Handler = ([String: Any]) -> Bool

    public let scheme: String

    public var shouldFallback: Bool = false

    public var options: Options = [
        .decodePlusSymbols
    ]

    private var _definitions: [Definition] = []

    public init(scheme: String) {
        self.scheme = scheme
    }

    public func reset() {
        options = [.decodePlusSymbols]

        removeAllDefinitions()
    }

    var definitions: [Definition] {
        return _definitions
    }

    private func append(definition: Definition) {
        if definition.priority == 0 || _definitions.isEmpty {
            _definitions.append(definition)
        } else {
            for (index, existingRoute) in _definitions.enumerated() where existingRoute.priority < definition.priority {
                _definitions.insert(definition, at: index)
                break
            }
            if !_definitions.contains(definition) {
                _definitions.append(definition)
            }
        }
        definition.configure(scheme: scheme)
    }

    private func remove(definition: Definition) {
        guard let index = _definitions.firstIndex(of: definition) else {
            return
        }
        _definitions.remove(at: index)
    }

    private func removeAllDefinitions() {
        _definitions.removeAll()
    }

    public subscript(pattern: String) -> Handler? {
        get {
            return nil
        }
        set {
            if newValue == nil {
                remove(pattern: pattern)
            } else {
                add(pattern: pattern, handler: newValue)
            }
        }
    }

    public func add(definition: Definition) {
        let optionalRoutePatterns: [String] = definition.pattern.route_expandOptionalRoutePatterns()

        if !optionalRoutePatterns.isEmpty {
            optionalRoutePatterns.forEach { pattern in
                append(definition: Definition(pattern: pattern, priority: definition.priority, handler: definition.handler))
            }
            return
        }

        append(definition: definition)
    }

    public func add(pattern: String, priority: Int = 0, handler: Handler? = nil) {
        let optionalRoutePatterns: [String] = pattern.route_expandOptionalRoutePatterns()

        let definition: Definition = Definition(pattern: pattern, priority: priority, handler: handler)

        if !optionalRoutePatterns.isEmpty {
            optionalRoutePatterns.forEach { pattern in
                append(definition: Definition(pattern: pattern, priority: priority, handler: handler))
            }
            return
        }

        append(definition: definition)
    }

    public func add(patterns: [String], handler: Handler? = nil) {
        patterns.forEach { pattern in
            add(pattern: pattern, handler: handler)
        }
    }

    public func remove(pattern: String) {
        var routeIndex: Int?

        _definitions.enumerated().forEach { index, route in
            if route.pattern == pattern {
                routeIndex = index
                return
            }
        }

        if let index = routeIndex {
            _definitions.remove(at: index)
        }
    }

    public func canRoute(resource: Resource) -> Bool {
        return route(resource: resource, parameters: [:], executeRouteBlock: false)
    }

    public func route(resource: Resource, parameters: [String: Any] = [:]) -> Bool {
        return route(resource: resource, parameters: parameters, executeRouteBlock: true)
    }

    private func route(resource: Resource, parameters: [String: Any], executeRouteBlock: Bool) -> Bool {
        guard let url = resource.url else {
            return false
        }

        var didRoute: Bool = false

        let request: Request = Request(url: url, options: options, additionalParams: parameters)

        let routes: [Definition] = _definitions

        for route in routes {
            let response = route.response(for: request)

            guard response.isMatch else {
                continue
            }
            if !executeRouteBlock {
                return true
            }
            didRoute = route.handle(parameters: response.parameters)

            if didRoute {
                break
            }
        }

        if !didRoute {
            print("Could not find a matching route")
        }

        return didRoute
    }
}

@discardableResult
public func << (left: Routes, right: Definition) -> Routes {
    left.add(definition: right)
    return left
}
