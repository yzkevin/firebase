// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FirebaseCore
import Foundation
import XCTest

@_implementationOnly import FirebaseCoreExtension

@testable import FirebaseVertexAI

@available(iOS 15.0, macOS 12.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
class VertexComponentTests: XCTestCase {
  static let projectID = "test-project-id"
  static let apiKey = "test-api-key"

  static var app: FirebaseApp?

  let location = "test-location"

  override class func setUp() {
    super.setUp()
    if app == nil {
      let options = FirebaseOptions(googleAppID: "0:0000000000000:ios:0000000000000000",
                                    gcmSenderID: "00000000000000000-00000000000-000000000")
      options.projectID = VertexComponentTests.projectID
      options.apiKey = VertexComponentTests.apiKey
      FirebaseApp.configure(options: options)
      app = FirebaseApp(instanceWithName: "test", options: options)
    }
  }

  /// Test that the objc class is available for the component system to update the user agent.
  func testComponentsBeingRegistered() throws {
    XCTAssertNotNil(NSClassFromString("FIRVertexAIComponent"))
  }

  /// Tests that a vertex instance can be created properly.
  func testVertexInstanceCreation() throws {
    let app = try XCTUnwrap(VertexComponentTests.app)

    let vertex = VertexAI.vertexAI(app: app, location: location)

    XCTAssertNotNil(vertex)
    XCTAssertEqual(vertex.projectID, VertexComponentTests.projectID)
    XCTAssertEqual(vertex.apiKey, VertexComponentTests.apiKey)
    XCTAssertEqual(vertex.location, location)
  }

  /// Tests that a vertex instances are reused properly.
  func testMultipleComponentInstancesCreated() throws {
    let app = try XCTUnwrap(VertexComponentTests.app)
    let vertex1 = VertexAI.vertexAI(app: app, location: location)
    let vertex2 = VertexAI.vertexAI(app: app, location: location)

    // Ensure they're the same instance.
    XCTAssert(vertex1 === vertex2)

    let vertex3 = VertexAI.vertexAI(app: app, location: "differentLocation")
    XCTAssert(vertex1 !== vertex3)
  }

  /// Test that vertex instances get deallocated.
  func testVertexLifecycle() throws {
    weak var weakApp: FirebaseApp?
    weak var weakVertex: VertexAI?
    try autoreleasepool {
      let options = FirebaseOptions(googleAppID: "0:0000000000000:ios:0000000000000000",
                                    gcmSenderID: "00000000000000000-00000000000-000000000")
      options.projectID = VertexComponentTests.projectID
      options.apiKey = VertexComponentTests.apiKey
      let app1 = FirebaseApp(instanceWithName: "transitory app", options: options)
      weakApp = try XCTUnwrap(app1)
      let vertex = VertexAI(app: app1, location: "transitory location")
      weakVertex = vertex
      XCTAssertNotNil(weakVertex)
    }
    XCTAssertNil(weakApp)
    XCTAssertNil(weakVertex)
  }

  func testModelResourceName() throws {
    let app = try XCTUnwrap(VertexComponentTests.app)
    let vertex = VertexAI.vertexAI(app: app, location: location)
    let model = "test-model-name"

    let modelResourceName = vertex.modelResourceName(modelName: model)

    XCTAssertEqual(
      modelResourceName,
      "projects/\(vertex.projectID)/locations/\(vertex.location)/publishers/google/models/\(model)"
    )
  }

  func testGenerativeModel() async throws {
    let app = try XCTUnwrap(VertexComponentTests.app)
    let vertex = VertexAI.vertexAI(app: app, location: location)
    let modelName = "test-model-name"
    let modelResourceName = vertex.modelResourceName(modelName: modelName)
    let systemInstruction = ModelContent(role: "system", parts: "test-system-instruction-prompt")

    let generativeModel = vertex.generativeModel(
      modelName: modelName,
      systemInstruction: systemInstruction
    )

    XCTAssertEqual(generativeModel.modelResourceName, modelResourceName)
    XCTAssertEqual(generativeModel.systemInstruction, systemInstruction)
  }
}
