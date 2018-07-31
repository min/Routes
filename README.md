Routes 🗺
========

This library is a Swift port/fork of the popular Objective-C library [JLRoutes](https://www.github.com/joeldev/JLRoutes). Much ❤️ and credit goes to [joeldev](https://www.github.com/joeldev) for creating such a delightful routing library.

Routes is a pure-Swift URL routing library with a simple block-based API. It is designed to make it very easy to handle complex URL schemes in your application with minimal code. 

### Installation ###
Routes is available for installation using Carthage (add `github "min/Routes"` to your `Cartfile`).

### Requirements ###
- iOS 9.0+ / tvOS 9.0+ / watchOS 2.0+
- Swift 4

### Getting Started ###

[Configure your URL schemes in Info.plist.](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW2)

```swift

class AppDelegate: UIResponder, UIApplicationDelegate {
    let router: Router = Router()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        router.default.add(pattern: "/user/view/:user_id") { parameters in
            let userId = parameters["user_id"]
            
            // present UI for viewing user with userId
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return router.route(url: url)
    }
}

```

After adding a route for `/user/view/:user_id`, the following call will cause the handler block to be called with a dictionary containing `{"user_id": "min"}`:

```swift
let url = URL(string: "myapp://user/view/min")!
router.route(url: url)
```

### Handler Block Chaining ###

The handler block is expected to return a boolean for if it has handled the route or not. If the block returns `false`, Routes will behave as if that route is not a match and it will continue looking for a match. A route is considered to be a match if the pattern string matches **and** the block returns `true`.

It is also important to note that if you pass nil for the handler block, an internal handler block will be created that simply returns `true`.


### Schemes ###

Routes supports setting up routes within a specific URL scheme. Routes that are set up within a scheme can only be matched by URLs that use a matching URL scheme. By default, all routes go into the global scheme.

```swift
let router = Router()

router.default.add(pattern: "foo") { parameters in
    // This block is called if the scheme is not 'thing' or 'stuff' (see below)	
    return true
}

router["thing"].add(pattern: "foo") { parameters in
    // This block is called for thing://foo
    return true
}

router["stuff"].add(pattern: "foo") { parameters in
    // This block is called for stuff://foo
    return true
}
```

This example shows that you can declare the same routes in different schemes and handle them with different callbacks on a per-scheme basis.

Continuing with this example, if you were to add the following route:

```swift
let router = Router()

router.default.add(pattern: "/global") { parameters in
    return true
}
```

and then try to route the URL `thing://global`, it would not match because that route has not been declared within the `thing` scheme but has instead been declared within the global scheme (which we'll assume is how the developer wants it). However, you can easily change this behavior by setting the following property to `true`:

```swift
let router = Router()

router["thing"].shouldFallbackToGlobalRoutes = true
```

This tells Routes that if a URL cannot be routed within the `thing` scheme (aka, it starts with `thing:` but no appropriate route can be found), try to recover by looking for a matching route in the global routes scheme as well. After setting that property to `true`, the URL `thing://global` would be routed to the `/global` handler block.


### Wildcards ###

Routes supports setting up routes that will match an arbitrary number of path components at the end of the routed URL. An array containing the additional path components will be added to the parameters dictionary with the key `Definition.Keys.wildcard`.

For example, the following route would be triggered for any URL that started with `/wildcard/`, but would be rejected by the handler if the next component wasn't `joker`.

```swift
let router = Router()

router.default.add(pattern: "/wildcard/*") { parameters in
    let components = parameters[Definition.Keys.wildcard]

    guard let component = components.first, component == "joker" else {
        return false
    }

    return true
}
```

### Optional Routes ###

Routes supports setting up routes with optional parameters. At the route registration moment, Routes will register multiple routes with all combinations of the route with the optional parameters and without the optional parameters. For example, for the route `/the(/foo/:a)(/bar/:b)`, it will register the following routes:

- `/the/foo/:a/bar/:b`
- `/the/foo/:a`
- `/the/bar/:b`
- `/the`

### License ###
MIT. See the [LICENSE](LICENSE) file for details.
