//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftAwsLambda open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftAwsLambda project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftAwsLambda project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import SwiftAwsLambda
import XCTest

class LambdaRunnerTest: XCTestCase {
    func testSuccess() throws {
        class Behavior: LambdaServerBehavior {
            let requestId = NSUUID().uuidString
            let payload = "hello"
            func getWork() -> GetWorkResult {
                return .success(requestId: requestId, payload: payload)
            }

            func processResponse(requestId: String, response: String) -> ProcessResponseResult {
                XCTAssertEqual(self.requestId, requestId, "expecting requestId to match")
                XCTAssertEqual(payload, response, "expecting response to match")
                return .success()
            }

            func processError(requestId _: String, error _: ErrorResponse) -> ProcessErrorResult {
                XCTFail("should not report error")
                return .failure(.InternalServerError)
            }
        }
        let result = try runLambda(behavior: Behavior(), handler: EchoHandler()) // .wait()
        assertRunLambdaResult(result: result)
    }

    func testFailure() throws {
        class Behavior: LambdaServerBehavior {
            static let error = "boom"
            let requestId = NSUUID().uuidString
            func getWork() -> GetWorkResult {
                return .success(requestId: requestId, payload: "hello")
            }

            func processResponse(requestId _: String, response _: String) -> ProcessResponseResult {
                XCTFail("should report error")
                return .failure(.InternalServerError)
            }

            func processError(requestId: String, error: ErrorResponse) -> ProcessErrorResult {
                XCTAssertEqual(self.requestId, requestId, "expecting requestId to match")
                XCTAssertEqual(Behavior.error, error.errorMessage, "expecting error to match")
                return .success()
            }
        }
        let result = try runLambda(behavior: Behavior(), handler: FailedHandler(Behavior.error)) // .wait()
        assertRunLambdaResult(result: result)
    }
}
