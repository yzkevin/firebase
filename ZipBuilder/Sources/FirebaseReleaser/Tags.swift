/*
 * Copyright 2020 Google LLC
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

import Foundation

import FirebaseManifest
import Utils

enum Tags {
  static func createTags(gitRoot: URL, deleteExistingTags: Bool = false) {
    let manifest = FirebaseManifest.shared
    createTag(gitRoot: gitRoot, tag: "CocoaPods-\(manifest.version)",
      deleteExistingTags: deleteExistingTags)
    createTag(gitRoot: gitRoot, tag: "CocoaPods-\(manifest.version)-beta",
      deleteExistingTags: deleteExistingTags)

    for pod in manifest.pods {
      if pod.isFirebase {
        continue
      }
      if !pod.name.starts(with: "Google") {
        fatalError("Unrecognized Other Pod: \(pod.name). Only Google prefix is recognized")
      }
      guard let version = pod.podVersion else {
        fatalError("Non-Firebase pod \(pod.name) is missing a version")
      }
      let tag = pod.name.replacingOccurrences(of: "Google", with: "") + "-" + version
      createTag(gitRoot: gitRoot, tag: tag, deleteExistingTags: deleteExistingTags)
    }
  }

  static func updateTags(gitRoot: URL) {
    createTags(gitRoot: gitRoot, deleteExistingTags: true)
  }

  private static func createTag(gitRoot: URL, tag: String, deleteExistingTags: Bool) {
    if deleteExistingTags {
      verifyTagsAreSafeToDelete()
      Shell.executeCommand("git tag --delete \(tag)", workingDir: gitRoot)
      Shell.executeCommand("git push --delete origin \(tag)", workingDir: gitRoot)
    }
    Shell.executeCommand("git tag \(tag)", workingDir: gitRoot)
    Shell.executeCommand("git push origin \(tag)", workingDir: gitRoot)
  }

  private static func verifyTagsAreSafeToDelete() {
    var homeDirURL: URL
    if #available(OSX 10.12, *) {
      homeDirURL = FileManager.default.homeDirectoryForCurrentUser
    } else {
      fatalError("Run on at least macOS 10.12")
    }
    let manifest = FirebaseManifest.shared
    let firebasePublicURL = homeDirURL.appendingPathComponents(
      [".cocoapods", "repos", "cocoapods", "Specs", "0", "3", "5", "Firebase"]
    )

    guard FileManager.default.fileExists(atPath: firebasePublicURL.path) else {
      fatalError("You must have the CocoaPods Spec repo installed to retag versions.")
    }

    guard !FileManager.default.fileExists(atPath:
      firebasePublicURL.appendingPathComponent(manifest.version).path) else {
      fatalError("Do not remove tag of a published Firebase version.")
    }
  }
}
