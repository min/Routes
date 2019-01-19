//
//  Request.swift
//  Routes
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import Foundation

struct Request {
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
            self.pathComponents = URLComponents.route_path(
                components: &components,
                treatsHostAsPathComponent: options.contains(.treatHostAsPathComponent)
            ).route_trimmedPathComponents()

            self.queryParams = components.route_queryParams()
        } else {
            self.pathComponents = []

            self.queryParams = [:]
        }
    }
}
