// Copyright 2023 Google LLC
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

import Foundation

private let kHttpsProtocol = "https:"
private let kHttpProtocol = "http:"

private let kEmulatorHostAndPrefixFormat = "%@/%@"

private var gAPIHost = "www.googleapis.com"

private let kFirebaseAuthAPIHost = "www.googleapis.com"
private let kIdentityPlatformAPIHost = "identitytoolkit.googleapis.com"

private let kFirebaseAuthStagingAPIHost = "staging-www.sandbox.googleapis.com"
private let kIdentityPlatformStagingAPIHost =
  "staging-identitytoolkit.sandbox.googleapis.com"

/// Represents a request to an identity toolkit endpoint.
@available(iOS 13, tvOS 13, macOS 10.15, macCatalyst 13, watchOS 7, *)
open class IdentityToolkitRequest {
  /// Gets the RPC's endpoint.
  let endpoint: String

  /// Gets the client's API key used for the request.
  var apiKey: String

  /// The tenant ID of the request. nil if none is available.
  let tenantID: String?

  let _requestConfiguration: AuthRequestConfiguration

  let _useIdentityPlatform: Bool

  let _useStaging: Bool

  init(endpoint: String, requestConfiguration: AuthRequestConfiguration,
       useIdentityPlatform: Bool = false, useStaging: Bool = false) {
    self.endpoint = endpoint
    apiKey = requestConfiguration.apiKey
    _requestConfiguration = requestConfiguration
    _useIdentityPlatform = useIdentityPlatform
    _useStaging = useStaging
    tenantID = requestConfiguration.auth?.tenantID
  }

  func containsPostBody() -> Bool {
    true
  }

  /// Returns the request's full URL.
  func requestURL() -> URL {
    let apiProtocol: String
    let apiHostAndPathPrefix: String
    let urlString: String
    let emulatorHostAndPort = _requestConfiguration.emulatorHostAndPort
    if _useIdentityPlatform {
      if let emulatorHostAndPort = emulatorHostAndPort {
        apiProtocol = kHttpProtocol
        apiHostAndPathPrefix = "\(emulatorHostAndPort)/\(kIdentityPlatformAPIHost)"
      } else if _useStaging {
        apiHostAndPathPrefix = kIdentityPlatformStagingAPIHost
        apiProtocol = kHttpsProtocol
      } else {
        apiHostAndPathPrefix = kIdentityPlatformAPIHost
        apiProtocol = kHttpsProtocol
      }
      urlString = "\(apiProtocol)//\(apiHostAndPathPrefix)/v2/\(endpoint)?key=\(apiKey)"

    } else {
      if let emulatorHostAndPort = emulatorHostAndPort {
        apiProtocol = kHttpProtocol
        apiHostAndPathPrefix = "\(emulatorHostAndPort)/\(kFirebaseAuthAPIHost)"
      } else if _useStaging {
        apiProtocol = kHttpsProtocol
        apiHostAndPathPrefix = kFirebaseAuthStagingAPIHost
      } else {
        apiProtocol = kHttpsProtocol
        apiHostAndPathPrefix = kFirebaseAuthAPIHost
      }
      urlString =
        "\(apiProtocol)//\(apiHostAndPathPrefix)/identitytoolkit/v3/relyingparty/\(endpoint)?key=\(apiKey)"
    }
    return URL(string: urlString)!
  }

  /// Returns the request's configuration.
  func requestConfiguration() -> AuthRequestConfiguration {
    _requestConfiguration
  }

  // MARK: Internal API for development

  static var host: String { gAPIHost }
  static func setHost(_ host: String) {
    gAPIHost = host
  }
}
