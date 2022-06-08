// Copyright 2022 Google LLC
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

import FirebaseStorageInternal

/** Contains the prefixes and items returned by a `StorageReference.list()` call. */
@objc(FIRStorageListResult) open class StorageListResult: NSObject {
  /**
   * The prefixes (folders) returned by a `list()` operation.
   *
   * - Returns: A list of prefixes (folders).
   */
  @objc public let prefixes: [StorageReference]

  /**
   * The objects (files) returned by a `list()` operation.
   *
   * - Returns: A page token if more results are available.
   */
  @objc public let items: [StorageReference]

  /**
   * Returns a token that can be used to resume a previous `list()` operation. `nil`
   * indicates that there are no more results.
   *
   * - Returns: A page token if more results are available.
   */
  @objc public let pageToken: String?

  // MARK: - NSObject overrides

  @objc override open func copy() -> Any {
    return self.copy()
  }

  // MARK: - Internal APIs
  
  internal convenience init(with dictionary: [String: Any], reference: FIRIMPLStorageReference) {
    var prefixes = [FIRIMPLStorageReference]()
    var items = [FIRIMPLStorageReference]()
    
    let rootReference = reference.root()
    if let prefixEntries = dictionary["prefixes"] as? [String] {
      for prefixEntry in prefixEntries {
        var pathWithoutTrailingSlash = prefixEntry
        if prefixEntry.hasSuffix("/") {
          pathWithoutTrailingSlash = String(prefixEntry.dropLast())
        }
        prefixes.append(rootReference.child(pathWithoutTrailingSlash))
      }
    }
    
    if let itemEntries = dictionary["items"] as? [[String: String]] {
      for itemEntry in itemEntries {
        if let item = itemEntry["name"] {
          items.append(rootReference.child(item))
        }
      }
    }
    self.init(withPrefixes: prefixes, items: items, pageToken:nil)
  }
  
  internal init(withPrefixes prefixes: [FIRIMPLStorageReference],
                items: [FIRIMPLStorageReference],
                pageToken: String?) {
    self.prefixes = prefixes.map { StorageReference($0) }
    self.items = items.map { StorageReference($0) }
    self.pageToken = pageToken
  }
}
