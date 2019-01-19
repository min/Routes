//
//  String+Utilities.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

extension String {
    func route_variableValue(decodePlusSymbols: Bool) -> String {
        guard decodePlusSymbols else {
            return self
        }

        return self.replacingOccurrences(of: "+", with: " ", options: [.literal], range: (startIndex..<endIndex))
    }

    func route_trimmedPathComponents() -> [String] {
        return trimmingCharacters(in: .init(charactersIn: "/")).components(separatedBy: "/")
    }

    func route_subpathsForPatterns() -> [Subpath] {
        var subpaths: [Subpath] = []

        let scanner: Scanner = Scanner(string: self)

        while !scanner.isAtEnd {
            var preOptionalSubpath: NSString?

            var didScan: Bool = scanner.scanUpTo("(", into: &preOptionalSubpath)

            if !didScan {
                let start: Index = index(startIndex, offsetBy: scanner.scanLocation)
                let end: Index = index(startIndex, offsetBy: scanner.scanLocation + 1)

                assert(self[start..<end] == "(", "Unexpected character")
            }

            if !scanner.isAtEnd {
                scanner.scanLocation += 1
            }

            if let preOptionalSubpath = preOptionalSubpath {
                if preOptionalSubpath.length > 0 && preOptionalSubpath != ")" && preOptionalSubpath != "/" {
                    subpaths.append(
                        Subpath(
                            subpathComponents: String(preOptionalSubpath).route_trimmedPathComponents(),
                            isOptionalSubpath: false
                        )
                    )
                }
            }

            if scanner.isAtEnd {
                break
            }

            var optionalSubpath: NSString?

            didScan = scanner.scanUpTo(")", into: &optionalSubpath)

            assert(didScan, "Could not find closing parenthesis")

            scanner.scanLocation += 1

            if let optionalSubpath = optionalSubpath, optionalSubpath.length > 0 {
                subpaths.append(
                    Subpath(
                        subpathComponents: String(optionalSubpath).route_trimmedPathComponents(),
                        isOptionalSubpath: true
                    )
                )
            }
        }

        return subpaths
    }

    func route_expandOptionalRoutePatterns() -> [String] {
        guard range(of: "(") != nil else {
            return []
        }

        let subpaths: [Subpath] = route_subpathsForPatterns()

        guard !subpaths.isEmpty else {
            return []
        }

        let requiredSubpaths: Set<Subpath> = Set<Subpath>(subpaths.filter({ !$0.isOptionalSubpath }))

        let allSubpathCombinations: [[Subpath]] = subpaths.route_allOrderedCombinations()

        let validSubpathCombinations: [[Subpath]] = allSubpathCombinations.filter { subpath in
            requiredSubpaths.isSubset(of: subpath)
        }

        var validSubpathRouteStrings: [String] = validSubpathCombinations.map { subpaths in
            var routePattern: String = "/"

            subpaths.forEach { subpath in
                let subpathString: String = subpath.subpathComponents.joined(separator: "/")

                routePattern = (routePattern as NSString).appendingPathComponent(subpathString)
            }

            return routePattern
        }

        validSubpathRouteStrings = validSubpathRouteStrings.sorted(by: { lhs, rhs -> Bool in
            lhs.count > rhs.count
        })

        return validSubpathRouteStrings
    }
}
