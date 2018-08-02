//
//  RoutesTests.swift
//  RoutesTests
//
//  Created by Min Kim on 7/30/18.
//  Copyright © 2018 Min Kim. All rights reserved.
//

import XCTest
@testable import Routes

class RoutesTests: XCTestCase {
    var lastMatch: [String: Any]?

    var didRoute: Bool = false

    var defaultRouteHandler: Routes.Handler {
        return { params in
            self.lastMatch = params
            return true
        }
    }

    var router: Router = Router()

    override func setUp() {
        super.setUp()

        didRoute = false
        lastMatch = nil

        router = Router()
    }

    func testRoutesArray() {
        let handler = defaultRouteHandler

        router.default["/global1"] = handler
        router.default["/global2"] = handler
        router.default["/global3"] = handler

        let globalRoutes = router.default.definitions

        XCTAssertEqual(globalRoutes.count, 3)

        XCTAssertEqual(globalRoutes[0].pattern, "/global1")
        XCTAssertEqual(globalRoutes[1].pattern, "/global2")
        XCTAssertEqual(globalRoutes[2].pattern, "/global3")

        router["scheme"]["/scheme1"] = handler
        router["scheme"]["/scheme2"] = handler

        let schemeRoutes: [Definition] = router["scheme"].definitions

        XCTAssertEqual(schemeRoutes.count, 2)
        XCTAssertEqual(schemeRoutes[0].pattern, "/scheme1")
        XCTAssertEqual(schemeRoutes[1].pattern, "/scheme2")

        let nonexistant: [Definition] = router["foo"].definitions

        XCTAssertEqual(nonexistant.count, 0)
    }

    func testAllRoutes() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/global1", handler: handler)
        router.default.add(pattern: "/global2", handler: handler)
        router.default.add(pattern: "/global3", handler: handler)
        router["scheme"].add(pattern: "/scheme1", handler: handler)
        router["scheme"].add(pattern: "/scheme2", handler: handler)

        let definitionMapping: [String: [Definition]] = router.definitionMapping

        let globalRoutes: [Definition]? = definitionMapping[Router.defaultScheme]

        XCTAssertEqual(globalRoutes?.count, 3)
        XCTAssertEqual(globalRoutes?[0].pattern, "/global1")
        XCTAssertEqual(globalRoutes?[1].pattern, "/global2")
        XCTAssertEqual(globalRoutes?[2].pattern, "/global3")

        let schemeRoutes: [Definition]? = definitionMapping["scheme"]

        XCTAssertEqual(schemeRoutes?.count, 2)
        XCTAssertEqual(schemeRoutes?[0].pattern, "/scheme1")
        XCTAssertEqual(schemeRoutes?[1].pattern, "/scheme2")
    }

    func testRouting() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/test", handler: handler)

        router.default.add(pattern: "/user/view/:user_id", handler: handler)
        router.default.add(pattern: "/:object/:action/:primaryKey", handler: handler)
        router.default.add(pattern: "/", handler: handler)
        router.default.add(pattern: "/:", handler: handler)
        router.default.add(pattern: "/interleaving/:param1/foo/:param2", handler: handler)
        router.default.add(pattern: "/xyz/wildcard/*", handler: handler)
        router.default.add(pattern: "/route/:param/*", handler: handler)
        router.default.add(pattern: "/required/:requiredParam(/optional/:optionalParam)(/moreOptional/:moreOptionalParam)", handler: handler)

        reset()

        assertNoLastMatch()

        route(urlString: "tests:/")
        assertAnyRouteMatched()
        assertPattern("/")
        assertParameterCount(0)

        route(urlString: "tests://")
        assertAnyRouteMatched()
        assertPattern("/")
        assertParameterCount(0)

        route(urlString: "tests://test?")
        assertAnyRouteMatched()
        assertParameterCount(0)
        assertPattern("/test")

        route(urlString: "tests://test/")
        assertAnyRouteMatched()
        assertParameterCount(0)
        assertPattern("/test")

        route(urlString: "tests://test")
        assertAnyRouteMatched()
        assertParameterCount(0)

        route(urlString: "tests://?key=value")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "key", value: "value")

        route(urlString: "tests://user/view/min")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "user_id", value: "min")

        route(urlString: "tests://user/view/min/")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "user_id", value: "min")

        route(urlString: "tests://user/view/min%20kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "user_id", value: "min kim")

        route(urlString: "tests://user/view/min?foo=bar&thing=stuff")
        assertAnyRouteMatched()
        assertParameterCount(3)
        assertParameter(key: "user_id", value: "min")
        assertParameter(key: "foo", value: "bar")
        assertParameter(key: "thing", value: "stuff")

        route(urlString: "tests://user/view/min#foo=bar&thing=stuff")
        assertAnyRouteMatched()
        assertParameterCount(3)
        assertParameter(key: "user_id", value: "min")
        assertParameter(key: "foo", value: "bar")
        assertParameter(key: "thing", value: "stuff")

        route(urlString: "tests://user/view/min?user_id=1234")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "user_id", value: "min")

        route(urlString: "tests://post/edit/123")
        assertAnyRouteMatched()
        assertParameterCount(3)
        assertParameter(key: "object", value: "post")
        assertParameter(key: "action", value: "edit")
        assertParameter(key: "primaryKey", value: "123")

        route(urlString: "tests://interleaving/paramvalue1/foo/paramvalue2")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "param1", value: "paramvalue1")
        assertParameter(key: "param2", value: "paramvalue2")

        route(urlString: "tests://xyz/wildcard")
        assertAnyRouteMatched()
        assertParameterCountIncludingWildcard(0)

        route(urlString: "tests://xyz/wildcard/matches/with/extra/path/components")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: Definition.Keys.wildcard, value: ["matches", "with", "extra", "path", "components"])

        route(urlString: "tests://route/matches/with/wildcard")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "param", value: "matches")
        assertParameter(key: Definition.Keys.wildcard, value: ["with", "wildcard"])

        route(urlString: "tests://doesnt/exist/and/wont/match")
        assertNoLastMatch()

        route(url: URL(string: "/test", relativeTo: URL(string: "http://localhost")!)!)
        assertAnyRouteMatched()
        assertPattern("/test")
        assertParameterCount(0)

        route(urlString: "tests://required/mustExist")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "requiredParam", value: "mustExist")

        route(urlString: "tests://required/mustExist/optional/mightExist")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "requiredParam", value: "mustExist")
        assertParameter(key: "optionalParam", value: "mightExist")

        route(urlString: "tests://required/mustExist/optional/mightExist/moreOptional/mightExistToo")
        assertAnyRouteMatched()
        assertParameterCount(3)
        assertParameter(key: "requiredParam", value: "mustExist")
        assertParameter(key: "optionalParam", value: "mightExist")
        assertParameter(key: "moreOptionalParam", value: "mightExistToo")
    }

    func testRoutingWithParameters() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/foo/:routeParam", handler: handler)

        route(urlString: "/foo/bar", parameters: ["stringParam": "stringValue", "nonStringParam": 123])
        assertAnyRouteMatched()
        assertParameterCount(3)
        assertParameter(key: "routeParam", value: "bar")
        assertParameter(key: "stringParam", value: "stringValue")
        assertParameter(key: "nonStringParam", value: 123)
    }

    func testFragmentRouting() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/user#/view/:userID", handler: handler)
        router.default.add(pattern: "/:object#/:action/:primaryKey", handler: handler)
        router.default.add(pattern: "/interleaving/:param1#/foo/:param2", handler: handler)
        router.default.add(pattern: "/xyz/wildcard#/*", handler: handler)
        router.default.add(pattern: "/route#/:param/*", handler: handler)
        router.default.add(pattern: "/required#/:requiredParam(/optional/:optionalParam)(/moreOptional/:moreOptionalParam)", handler: handler)

        reset()
        assertNoLastMatch()

        route(urlString: "tests://user#/view/min")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min")

        route(urlString: "tests://user#/view/min/")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min")

        route(urlString: "tests://user#/view/min%20kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min kim")
    }

    func testMultipleRoutePatterns() {
        router.default.add(patterns: ["multiple1", "multiple2"], handler: defaultRouteHandler)

        route(urlString: "tests://multiple1")
        assertAnyRouteMatched()
        assertParameterCount(0)

        route(urlString: "tests://multiple2")
        assertAnyRouteMatched()
        assertParameterCount(0)
    }

    func testPriority() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/test/priority/:level", handler: handler)
        router.default.add(pattern: "/test/priority/high", priority: 20, handler: handler)

        route(urlString: "tests://test/priority/high")
        assertAnyRouteMatched()
        assertPattern("/test/priority/high")

        router["priorityTest"].add(pattern: "/:foo/bar/:baz", priority: 20, handler: handler)
        router["priorityTest"].add(pattern: "/:foo/things/:baz", priority: 10, handler: handler)
        router["priorityTest"].add(pattern: "/:foo/:baz", priority: 1, handler: handler)

        route(urlString: "priorityTest://stuff/things/foo")
        assertAnyRouteMatched()

        route(urlString: "priorityTest://one/two")
        assertAnyRouteMatched()

        route(urlString: "priorityTest://stuff/bar/baz")
        assertAnyRouteMatched()
    }

    func testBlockReturnValue() {
        router.default.add(pattern: "/return/:value") { [weak self] parameters in
            self?.lastMatch = parameters

            return (parameters["value"] as? String) == "yes"
        }

        route(urlString: "tests://return/no")
        assertNoLastMatch()

        route(urlString: "tests://return/yes")
        assertAnyRouteMatched()
    }

    func testSchemes() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/test", handler: handler)
        router["namespaceTest1"].add(pattern: "/test", handler: handler)
        router["namespaceTest2"].add(pattern: "/test", handler: handler)

        route(urlString: "tests://test")
        assertAnyRouteMatched()
        assertScheme(Router.defaultScheme)

        route(urlString: "namespaceTest1://test")
        assertAnyRouteMatched()
        assertScheme("namespaceTest1")

        route(urlString: "namespaceTest2://test")
        assertAnyRouteMatched()
        assertScheme("namespaceTest2")
    }

    func testFallbackToGlobal() {
        let handler = self.defaultRouteHandler

        router.default.add(pattern: "/user/view/:userID", handler: handler)
        router["namespaceTest1"].add(pattern: "/test", handler: handler)
        router["namespaceTest2"].add(pattern: "/test", handler: handler)
        router["namespaceTest2"].shouldFallback = true

        route(urlString: "namespaceTest1://user/view/min")
        assertNoLastMatch()

        route(urlString: "namespaceTest2://user/view/min")
        assertAnyRouteMatched()
        assertScheme(Router.defaultScheme)
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min")
    }

    func testForRouteExistence() {
        router.default.add(pattern: "/test", handler: defaultRouteHandler)

        XCTAssertTrue(router.default.canRoute(resource: "tests:/test"), "Should state it can route known URL")
        XCTAssertFalse(router.default.canRoute(resource: "tests:/dfjkbsdkjfbskjdfb/sdasd"), "Should not state it can route unknown URL")
    }

    func testRouteRemoval() {
        let handler = self.defaultRouteHandler

        router.default.add(pattern: "/:", handler: handler)
        router["namespaceTest3"].add(pattern: "/test1", handler: handler)
        router["namespaceTest3"].add(pattern: "/test2", handler: handler)

        route(urlString: "namespaceTest3://test1")
        assertAnyRouteMatched()

        router["namespaceTest3"].remove(pattern: "/test1")

        route(urlString: "namespaceTest3://test1")
        assertNoLastMatch()

        route(urlString: "namespaceTest3://test2")
        assertAnyRouteMatched()
        assertScheme("namespaceTest3")

        router.unregister(scheme: "namespaceTest3")

        route(urlString: "namespaceTest3://test2")
        assertAnyRouteMatched()
        assertScheme(Router.defaultScheme)
    }

    func testPercentEncoding() {
        router.default.add(pattern: "/user/view/:userID", handler: defaultRouteHandler)
        router.default.shouldDecodePlusSymbols = false

        route(urlString: "tests://user/view/min%21kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min!kim")

        route(urlString: "tests://user/view/min%23kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min#kim")

        route(urlString: "tests://user/view/min%24kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min$kim")

        route(urlString: "tests://user/view/min%26kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min&kim")

        route(urlString: "tests://user/view/min%27kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min'kim")

        route(urlString: "tests://user/view/min%28kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min(kim")

        route(urlString: "tests://user/view/min%29kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min)kim")

        route(urlString: "tests://user/view/min%2Akim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min*kim")

        route(urlString: "tests://user/view/min%2Bkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min+kim")

        route(urlString: "tests://user/view/min%2Ckim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min,kim")

        route(urlString: "tests://user/view/min%3Akim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min:kim")

        route(urlString: "tests://user/view/min%3Bkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min;kim")

        route(urlString: "tests://user/view/min%3Dkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min=kim")

        route(urlString: "tests://user/view/min%3Fkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min?kim")

        route(urlString: "tests://user/view/min%40kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min@kim")

        route(urlString: "tests://user/view/min%5Bkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min[kim")

        route(urlString: "tests://user/view/min%5Dkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min]kim")
    }

    func testDecodePlusSymbols() {
        router.default.add(pattern: "/user/view/:userID", handler: defaultRouteHandler)
        router.default.shouldDecodePlusSymbols = true

        route(urlString: "tests://user/view/min%2Bkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min kim")

        route(urlString: "tests://user/view/min+kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min kim")

        route(urlString: "tests://user/view/test?name=min+kim")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "name", value: "min kim")

        route(urlString: "tests://user/view/test?people=min+kim&people=foo+bar")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "people", value: ["min kim", "foo bar"])

        router.default.shouldDecodePlusSymbols = false

        route(urlString: "tests://user/view/min%2Bkim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min+kim")

        route(urlString: "tests://user/view/min+kim")
        assertAnyRouteMatched()
        assertParameterCount(1)
        assertParameter(key: "userID", value: "min+kim")

        route(urlString: "tests://user/view/test?name=min+kim")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "name", value: "min+kim")

        route(urlString: "tests://user/view/test?people=min+kim&people=foo+bar")
        assertAnyRouteMatched()
        assertParameterCount(2)
        assertParameter(key: "people", value: ["min+kim", "foo+bar"])
    }

    func testVariableEmptyFollowedByWildcard() {
        router["wildcardTests"].add(pattern: "list/:variable/detail/:variable2/*")

        route(urlString: "wildcardTests://list/variable/detail/")
        assertNoLastMatch()

        route(urlString: "wildcardTests://list/variable/detail/variable2")
        assertAnyRouteMatched()
    }

    func testOptionalRoutesAtStart() {
        router.default.add(pattern: "/(rest/)(app/):object/:id", handler: defaultRouteHandler)

        XCTAssertEqual(router.default.definitions.count, 4)

        route(urlString: "foo://rest/app/aaa/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")

        route(urlString: "foo://app/aaa/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")

        route(urlString: "foo://rest/aaa/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")

        route(urlString: "foo://aaa/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")
    }

    func testOptionalRoutesAtEnd() {
        router.default["/path/:thing(/new)(/anotherpath/:anotherthing)"] = defaultRouteHandler

        XCTAssertEqual(router.default.definitions.count, 4)

        route(urlString: "foo://path/abc/new/anotherpath/def")
        assertAnyRouteMatched()
        assertParameter(key: "thing", value: "abc")
        assertParameter(key: "anotherthing", value: "def")

        route(urlString: "foo://path/foo/anotherpath/bar")
        assertAnyRouteMatched()
        assertParameter(key: "thing", value: "foo")
        assertParameter(key: "anotherthing", value: "bar")

        route(urlString: "foo://path/yyy/new")
        assertAnyRouteMatched()
        assertParameter(key: "thing", value: "yyy")

        route(urlString: "foo://path/zzz")
        assertAnyRouteMatched()
        assertParameter(key: "thing", value: "zzz")

        route(urlString: "foo://path/zzz/anotherpath")
        assertNoLastMatch()
    }

    func testOptionalRoutesInterleaved() {
        router.default.add(pattern: "/(rest/):object/(app/):id", handler: defaultRouteHandler)

        XCTAssertEqual(router.default.definitions.count, 4)

        route(urlString: "foo://rest/aaa/app/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")

        route(urlString: "foo://aaa/app/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")

        route(urlString: "foo://rest/aaa/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")

        route(urlString: "foo://aaa/bbb")
        assertAnyRouteMatched()
        assertParameter(key: "object", value: "aaa")
        assertParameter(key: "id", value: "bbb")
    }

    func testPassingURLStringsAsParams() {
        let handler = defaultRouteHandler

        router.default.add(pattern: "/web/:URLString", handler: handler)
        router.default.add(pattern: "/web", handler: handler)

        route(urlString: "tests://web/http%3A%2F%2Ffoobar.com%2Fbaz")
        assertAnyRouteMatched()
        assertParameter(key: "URLString", value: "http://foobar.com/baz")

        route(urlString: "tests://web?URLString=http%3A%2F%2Ffoobar.com%2Fbaz")
        assertAnyRouteMatched()
        assertParameter(key: "URLString", value: "http://foobar.com/baz")
    }

    func testArrayQueryParams() {
        let handler = self.defaultRouteHandler

        router.default.add(pattern: "/test/foo", handler: handler)

        route(urlString: "tests://test/foo?key=1&key=2&key=3&text=hi&text=there")
        assertAnyRouteMatched()
        assertParameter(key: "key", value: ["1", "2", "3"])
        assertParameter(key: "text", value: ["hi", "there"])
    }

    func testTreatsHostAsPathComponent() {
        let handler = self.defaultRouteHandler

        router.default.add(pattern: "/sign_in", handler: handler)
        router.default.add(pattern: "/path/:pathid", handler: handler)
        router.default.alwaysTreatsHostAsPathComponent = false

        route(urlString: "https://www.mydomain.com/sign_in")
        assertAnyRouteMatched()
        assertPattern("/sign_in")

        route(urlString: "https://www.mydomain.com/path/3")
        assertAnyRouteMatched()
        assertPattern("/path/:pathid")
        assertParameter(key: "pathid", value: "3")

        router.default.alwaysTreatsHostAsPathComponent = true

        route(urlString: "https://www.mydomain2.com/sign_in")
        assertNoLastMatch()

        route(urlString: "https://www.mydomain2.com/path/3")
        assertNoLastMatch()

        router.default.add(pattern: "/www.mydomain2.com/sign_in", handler: handler)
        router.default.add(pattern: "/www.mydomain2.com/path/:pathid", handler: handler)

        route(urlString: "https://www.mydomain2.com/sign_in")
        assertAnyRouteMatched()
        assertPattern("/www.mydomain2.com/sign_in")

        route(urlString: "https://www.mydomain2.com/path/3")
        assertAnyRouteMatched()
        assertPattern("/www.mydomain2.com/path/:pathid")
        assertParameter(key: "pathid", value: "3")
    }

    func testRouteDefinitionEquality() {
        let handler = self.defaultRouteHandler

        let routeA: Definition = Definition(pattern: "/foo", priority: 0, handler: handler)
        let routeB: Definition = Definition(pattern: "/foo", priority: 0, handler: handler)
        let routeC: Definition = Definition(pattern: "/foo/bar", priority: 0, handler: handler)

        XCTAssertEqual(routeA, routeB)

        routeB.configure(scheme: "scheme")

        XCTAssertNotEqual(routeA, routeB)
        XCTAssertNotEqual(routeA, routeC)
    }

    private func route(urlString: String, parameters: [String: Any] = [:]) {
        route(url: URL(string: urlString)!, parameters: parameters)
    }

    private func route(url: URL, parameters: [String: Any] = [:]) {
        self.lastMatch = nil
        self.didRoute = router.route(resource: url, parameters: parameters)
    }

    private func reset() {
        self.lastMatch = nil
        self.didRoute = false
    }

    private func assertParameterCount(_ count: Int) {
        guard let lastMatch = lastMatch else {
            XCTFail("Matched something")
            return
        }
        XCTAssertEqual(lastMatch.count - 3, count, "Expected parameter count")
    }

    private func assertParameterCountIncludingWildcard(_ count: Int) {
        guard let lastMatch = lastMatch else {
            XCTFail("Matched something")
            return
        }
        XCTAssertEqual(lastMatch.count - 4, count, "Expected parameter count")
    }

    private func assertAnyRouteMatched() {
        XCTAssertTrue(didRoute, "Expected any route to match")
    }

    private func assertNoLastMatch() {
        XCTAssertFalse(didRoute, "Expected not to route successfully")
    }

    private func assertParameter<Value: Equatable>(key: String, value: Value) {
        XCTAssertEqual(lastMatch?[key] as? Value, value)
    }

    private func assertPattern(_ pattern: String) {
        XCTAssertEqual(lastMatch?[Definition.Keys.pattern] as? String, pattern)
    }

    private func assertScheme(_ scheme: String) {
        XCTAssertEqual(lastMatch?[Definition.Keys.scheme] as? String, scheme)
    }
}
