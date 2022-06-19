/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import FirebaseRemoteConfig
import SwiftUI

#if compiler(>=5.5.2) && canImport(SwiftUI) && (arch(arm64) || arch(x86_64))
  /// A property wrapper that listens to a Remote Config value.
  @available(iOS 14.0, macOS 11.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, *)
  @propertyWrapper
  public struct RemoteConfigProperty<T: Decodable>: DynamicProperty {
    @State private var configValueObserver: RemoteConfigValueObservable<T>

    /// Remote Config key name for this property
    public let key: String

    /// Remote Config instance for this property
    public let remoteConfig: RemoteConfig

    /// Last fetched status of remote config values
    public var lastFetchStatus: RemoteConfigFetchStatus {
      return remoteConfig.lastFetchStatus
    }

    /// Last fetched time of remote config values
    public var lastFetchTime: Date? {
      return remoteConfig.lastFetchTime
    }

    public var wrappedValue: T {
      configValueObserver.configValue
    }

    /// Creates an instance by defining key.
    /// This property depends on default remote config.
    ///
    /// - Parameter key: key name
    public init(forKey key: String) {
      self.key = key
      remoteConfig = RemoteConfig.remoteConfig()

      _configValueObserver = State(
        wrappedValue: RemoteConfigValueObservable<T>(
          key: key,
          remoteConfig: RemoteConfig.remoteConfig()
        )
      )
    }

    /// Creates an instance by defining key and remote config instance.
    ///
    /// - Parameters:
    ///   - key: key name
    ///   - remoteConfig: remote config instance
    public init(forKey key: String,
                remoteConfig: RemoteConfig) {
      self.key = key
      self.remoteConfig = remoteConfig

      _configValueObserver = State(
        wrappedValue: RemoteConfigValueObservable<T>(
          key: key,
          remoteConfig: remoteConfig
        )
      )
    }
  }
#endif
