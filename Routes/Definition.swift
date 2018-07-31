//
//  Definition.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

public class Definition {
    public enum Keys {
        static let pattern: String = "__pattern__"
        static let scheme: String = "__scheme__"
        static let url: String = "__url__"
        static let wildcard: String = "__wildcard__"
    }

    public let pattern: String
    public let priority: Int
    public let handler: Routes.Handler?

    private(set) var scheme: String?
    private(set) var patternPathComponents: [String]

    public required init(pattern: String, priority: Int = 0, handler: Routes.Handler? = nil) {
        self.pattern = pattern
        self.priority = priority
        self.handler = handler

        var normalizedPattern: String = pattern
        if pattern.first == "/" {
            normalizedPattern = String(pattern.dropFirst())
        }

        self.patternPathComponents = normalizedPattern.components(separatedBy: "/")
    }

    public func handle(parameters: [String: Any]) -> Bool {
        if let handler = handler {
            return handler(parameters)
        }
        return true
    }

    public func configure(scheme: String) {
        self.scheme = scheme
    }

    private func variables(for request: Request) -> [String: Any]? {
        var variables: [String: Any] = [:]

        var isMatch: Bool = true

        for (index, patternComponent) in patternPathComponents.enumerated() {
            var urlComponent: String?
            let isPatternComponentWildcard = patternComponent == "*"

            if index < request.pathComponents.count {
                urlComponent = request.pathComponents[index]
            } else if !isPatternComponentWildcard {
                isMatch = false
                break
            }

            if patternComponent.hasPrefix(":") {
                guard let urlComponent = urlComponent else {
                    continue
                }
                let name: String = variableName(for: patternComponent)
                let value: String = variableValue(for: urlComponent)

                variables[name] = value.rte_variableValue(
                    decodePlusSymbols: request.options.contains(.decodePlusSymbols)
                )
            } else if isPatternComponentWildcard {
                let minRequiredParams: Int = index
                if request.pathComponents.count >= minRequiredParams {
                    let startIndex = request.pathComponents.index(request.pathComponents.startIndex, offsetBy: index)
                    let endIndex = startIndex.advanced(by: request.pathComponents.count - index)

                    variables[Definition.Keys.wildcard] = Array(request.pathComponents[startIndex..<endIndex])
                    isMatch = true
                } else {
                    isMatch = false
                }
                break
            } else if patternComponent != urlComponent {
                isMatch = false
                break
            }
        }

        if !isMatch {
            return nil
        }

        return variables
    }

    func response(for request: Request) -> Response {
        let patternContainsWildcard: Bool = patternPathComponents.contains("*")

        if request.pathComponents.count != patternPathComponents.count && !patternContainsWildcard {
            return .invalid
        }

        guard let routeVariables = variables(for: request) else {
            return .invalid
        }

        let matchParams = matchParameters(for: request, routeVariables: routeVariables)

        return Response(isMatch: true, parameters: matchParams)
    }

    private func variableName(for value: String) -> String {
        var name: String = value

        if name.count > 1 && name.first == ":" {
            name = String(name.dropFirst())
        }

        if name.count > 1 && name.last == "#" {
            name = String(name.dropLast())
        }

        return name
    }

    private func variableValue(for value: String) -> String {
        var variable: String = value.removingPercentEncoding ?? value

        if variable.count > 1 && variable.last == "#" {
            variable = String(variable.dropLast())
        }

        return variable
    }

    private func matchParameters(for request: Request, routeVariables: [String: Any]) -> [String: Any] {
        var parameters: [String: Any] = [:]

        let decodePlusSymbols: Bool = request.options.contains(.decodePlusSymbols)

        request.queryParams.rte_queryParams(decodePlusSymbols: decodePlusSymbols).forEach({
            parameters[$0.key] = $0.value
        })
        routeVariables.forEach({
            parameters[$0.key] = $0.value
        })
        request.additionalParams.forEach({
            parameters[$0.key] = $0.value
        })

        parameters[Definition.Keys.pattern] = pattern
        parameters[Definition.Keys.url] = request.url.absoluteString

        if let scheme = scheme {
            parameters[Definition.Keys.scheme] = scheme
        }

        return parameters
    }
}

extension Definition: Equatable, Hashable {
    public static func == (lhs: Definition, rhs: Definition) -> Bool {
        return lhs.scheme == rhs.scheme &&
            lhs.pattern == rhs.pattern &&
            lhs.patternPathComponents == rhs.patternPathComponents &&
            lhs.priority == rhs.priority
    }

    public var hashValue: Int {
        let value: Int =
            pattern.hashValue ^
            priority.hashValue ^
            (scheme ?? "").hashValue

        return patternPathComponents.reduce(value) { $0 ^ $1.hashValue }
    }
}
