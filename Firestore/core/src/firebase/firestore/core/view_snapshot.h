/*
 * Copyright 2019 Google
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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_CORE_VIEW_SNAPSHOT_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_CORE_VIEW_SNAPSHOT_H_

#if !defined(__OBJC__)
#error "This header only supports Objective-C++"
#endif  // !defined(__OBJC__)

#include <string>

@class FSTDocument;

namespace firebase {
namespace firestore {
namespace core {

/**
 * The types of changes that can happen to a document with respect to a view.
 * NOTE: We sort document changes by their type, so the ordering of this enum is
 * significant.
 */
enum class DocumentViewChangeType {
  kRemoved = 0,
  kAdded,
  kModified,
  kMetadata
};

/** A change to a single document's state within a view. */
class DocumentViewChange {
 public:
  DocumentViewChange() = default;

  DocumentViewChange(FSTDocument* document, DocumentViewChangeType type)
      : document_{document}, type_{type} {
  }

  FSTDocument* document() const {
    return document_;
  }
  DocumentViewChangeType type() const {
    return type_;
  }

  std::string ToString() const;
  size_t Hash() const;
  bool operator==(const DocumentViewChange& rhs) const;

 private:
  FSTDocument* document_ = nullptr;
  DocumentViewChangeType type_{};
};

/** The possible states a document can be in w.r.t syncing from local storage to the backend. */
enum class SyncState {
  None = 0,
  Local,
  Synced
};

// /** A set of changes to documents with respect to a view. This set is mutable. */
// @interface FSTDocumentViewChangeSet : NSObject

// /** Returns a new empty change set. */
// + (instancetype)changeSet;

// /** Takes a new change and applies it to the set. */
// - (void)addChange:(firebase::firestore::core::DocumentViewChange &&)change;

// /** Returns the set of all changes tracked in this set. */
// - (std::vector<firebase::firestore::core::DocumentViewChange>)changes;

// @end

}  // namespace core
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_CORE_VIEW_SNAPSHOT_H_
