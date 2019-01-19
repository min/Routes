//
//  AppDelegate.swift
//  Example
//
//  Created by Min Kim on 1/19/19.
//  Copyright © 2019 Min Kim. All rights reserved.
//

import UIKit
import Routes

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private let router: Router = .init()

    private let rootViewController: ViewController = .init()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        setupRoutes()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return router.route(to: url, parameters: [:])
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

    private func setupRoutes() {
        router.default.add(pattern: "/users/:id") { [weak self] parameters in
            guard let userId = parameters["id"] as? String else {
                return false
            }
            self?.rootViewController.configure(userId: userId)
            return true
        }
        router.default.add(pattern: "/books/:id") { [weak self] parameters in
            guard let bookId = parameters["id"] as? String else {
                return false
            }
            self?.rootViewController.configure(bookId: bookId)
            return true
        }
    }
}
