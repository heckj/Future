// The MIT License (MIT)
//
// Copyright (c) 2016-2018 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import Pill


// MARK: XCTestCase

var descriptions = [String]() // stack of test descriptions

extension XCTestCase {
    func test(_ description: String, _ block: () -> Void = {}) -> Void {
        precondition(Thread.isMainThread)

        descriptions.append(description)
        block()
        descriptions.removeLast()
    }
    
    func expect(_ description: String = "GenericExpectation", file: StaticString = #file, line: UInt = #line, _ block: (_ fulfill: @escaping () -> Void) -> Void) {
        precondition(Thread.isMainThread)

        descriptions.append(description)
        let expectation = self.expectation(description: descriptions.joined(separator: " -> "))
        descriptions.removeLast()

        block({ expectation.fulfill() })

        wait()
    }

    func expectation() -> XCTestExpectation {
        return self.expectation(description: "GenericExpectation")
    }

    func expectNotification(_ name: Notification.Name, object: AnyObject? = nil, handler: XCTNSNotificationExpectation.Handler? = nil) -> XCTestExpectation {
        return self.expectation(forNotification: NSNotification.Name(rawValue: name.rawValue), object: object, handler: handler)
    }

    func wait(_ timeout: TimeInterval = 2.0, handler: XCWaitCompletionHandler? = nil) {
        waitForExpectations(timeout: timeout, handler: handler)
    }
}

func rnd() -> Int {
    return Int(arc4random())
}

func rnd(_ uniform: Int) -> Int {
    return Int(arc4random_uniform(UInt32(uniform)))
}

func after(ticks: Int, execute body: @escaping () -> Void) {
    if ticks == 0 {
        body()
    } else {
        DispatchQueue.main.async {
            after(ticks: ticks - 1, execute: body)
        }
    }
}



// MARK: Promise

enum MyError: Swift.Error {
    case e1
    case e2
}

let sentinel = 1

extension Future {    
    class func fulfilledAsync() -> Future<Int, Error> {
        return Future<Int, Error>() { fulfill, _ in
            DispatchQueue.global().async {
                fulfill(sentinel)
            }
        }
    }

    class func rejectedAsync() -> Future<Int, MyError> {
        return Future<Int, MyError>() { _, reject in
            DispatchQueue.global().async {
                reject(MyError.e1)
            }
        }
    }
}

// MARK: Finisher

class Finisher {
    private var _count: Int
    private let _finish: () -> Void

    init(_ finish: @escaping () -> Void, _ count: Int) {
        self._finish = finish
        self._count = count
    }

    func finish() {
        _count -= 1
        XCTAssert(_count >= 0)
        if _count == 0 {
            _finish()
        }
    }
}
