//
//  Request.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

struct Request {
    struct Options: OptionSet {
        let rawValue: Int

        static let decodePlusSymbols: Options = .init(rawValue: 1 << 0)
        static let treatHostAsPathComponent: Options = .init(rawValue: 1 << 1)
    }

    let url: URL
    let queryParams: [String: Any]
    let pathComponents: [String]
    let additionalParams: [String: Any]
    let options: Options

    init(url: URL, options: Options = [], additionalParams: [String: Any] = [:]) {
        self.url = url
        self.additionalParams = additionalParams
        self.options = options

        if var components = URLComponents(string: url.absoluteString) {
            self.pathComponents = URLComponents.rte_path(
                components: &components,
                treatsHostAsPathComponent: options.contains(.treatHostAsPathComponent)
            ).rte_trimmedPathComponents()

            self.queryParams = components.rte_queryParams()
        } else {
            self.pathComponents = []

            self.queryParams = [:]
        }
    }
}
