/*
 * Copyright 2017 Google
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

#import "Firestore/Source/Local/FSTLevelDBKey.h"

#include <string>
#include <utility>
#include <vector>

#import "Firestore/Source/Model/FSTDocumentKey.h"

#include "Firestore/core/src/firebase/firestore/model/resource_path.h"
#include "Firestore/core/src/firebase/firestore/util/ordered_code.h"
#include "Firestore/core/src/firebase/firestore/util/string_apple.h"

namespace util = firebase::firestore::util;

namespace util = firebase::firestore::util;
using firebase::firestore::model::ResourcePath;

NS_ASSUME_NONNULL_BEGIN

using firebase::firestore::model::ResourcePath;
using firebase::firestore::util::OrderedCode;
using Firestore::StringView;
using leveldb::Slice;

static const char *kRemoteDocumentsTable = "remote_document";

/**
 * Labels for the components of keys. These serve to make keys self-describing.
 *
 * These are intended to sort similarly to keys in the server storage format.
 *
 * Note that the server writes component labels using the equivalent to
 * OrderedCode::WriteSignedNumDecreasing. This means that despite the higher numeric value, a
 * terminator sorts before a path segment. In order to avoid needing the WriteSignedNumDecreasing
 * code just for these values, this enum's values are in the reverse order to the server side.
 *
 * Most server-side values don't apply here. For example, the server embeds projects, databases,
 * namespaces and similar values in its entity keys where the clients just open a different
 * leveldb. Similarly, many of these values don't apply to the server since the server is backed
 * by spanner which natively has concepts of tables and indexes. Where there's overlap, a comment
 * denotes the server value from the storage_format_internal.proto.
 */
typedef NS_ENUM(int64_t, FSTComponentLabel) {
  /**
   * A terminator is the final component of a key. All complete keys have a terminator and a key
   * is known to be a key prefix if it doesn't have a terminator.
   */
  FSTComponentLabelTerminator = 0,  // TERMINATOR_COMPONENT = 63, server-side

  /** A table name component names the logical table to which the key belongs. */
  FSTComponentLabelTableName = 5,

  /** A component containing the batch ID of a mutation. */
  FSTComponentLabelBatchID = 10,

  /** A component containing the canonical ID of a query. */
  FSTComponentLabelCanonicalID = 11,

  /** A component containing the target ID of a query. */
  FSTComponentLabelTargetID = 12,

  /** A component containing a user ID. */
  FSTComponentLabelUserID = 13,

  /**
   * A path segment describes just a single segment in a resource path. Path segments that occur
   * sequentially in a key represent successive segments in a single path.
   *
   * This value must be greater than FSTComponentLabelTerminator to ensure that longer paths sort
   * after paths that are prefixes of them.
   *
   * This value must also be larger than other separators so that path suffixes sort after other
   * key components.
   */
  FSTComponentLabelPathSegment = 62,  // PATH = 60, server-side

  /** The maximum value that can be encoded by WriteSignedNumIncreasing in a single byte. */
  FSTComponentLabelUnknown = 63,
};

namespace {

/** Writes a component label to the given key destination. */
void WriteComponentLabel(std::string *dest, FSTComponentLabel label) {
  OrderedCode::WriteSignedNumIncreasing(dest, label);
}

/**
 * Reads a component label from the given key contents.
 *
 * If the read is unsuccessful or if the read was successful but the label that was read did not
 * match the expectedLabel returns NO and changes none of its arguments.
 *
 * If the read is successful, returns YES and contents will be updated to the next unread byte.
 */
BOOL ReadComponentLabelMatching(absl::string_view *contents, FSTComponentLabel expectedLabel) {
  int64_t rawResult = 0;
  absl::string_view tmp = *contents;
  if (OrderedCode::ReadSignedNumIncreasing(&tmp, &rawResult)) {
    if (rawResult == expectedLabel) {
      *contents = tmp;
      return YES;
    }
  }
  return NO;
}

/** Writes a component label and an encoded string to the given key destination. */
void WriteLabeledString(std::string *dest, FSTComponentLabel label, StringView value) {
  WriteComponentLabel(dest, label);
  OrderedCode::WriteString(dest, value);
}

/**
 * Reads a component label and a string from the given key contents and verifies that the label
 * matches the expectedLabel.
 *
 * If the read is unsuccessful or the label didn't match, returns NO, and changes none of its
 * arguments.
 *
 * If the read is successful, returns YES, contents will be updated to the next unread byte, and
 * value will be set to the decoded string value.
 */
BOOL ReadLabeledString(Slice *contents, FSTComponentLabel expectedLabel, std::string *value) {
  absl::string_view tmp(contents->data(), contents->size());
  if (ReadComponentLabelMatching(&tmp, expectedLabel)) {
    if (OrderedCode::ReadString(&tmp, value)) {
      *contents = leveldb::Slice(tmp.data(), tmp.size());
      return YES;
    }
  }

  return NO;
}

/**
 * Reads a component label and a string from the given key contents and verifies that the label
 * matches the expectedLabel and the string matches the expectedValue.
 *
 * If the read is unsuccessful, the label or didn't match, or the string value didn't match,
 * returns NO, and changes none of its arguments.
 *
 * If the read is successful, returns YES, contents will be updated to the next unread byte.
 */
BOOL ReadLabeledStringMatching(Slice *contents,
                               FSTComponentLabel expectedLabel,
                               const char *expectedValue) {
  std::string value;
  Slice tmp = *contents;
  if (ReadLabeledString(&tmp, expectedLabel, &value)) {
    if (value == expectedValue) {
      *contents = tmp;
      return YES;
    }
  }

  return NO;
}

/**
 * For each segment in the given resource path writes an FSTComponentLabelPathSegment component
 * label and a string containing the path segment.
 */
void WriteResourcePath(std::string *dest, const ResourcePath &path) {
  for (const auto &segment : path) {
    WriteComponentLabel(dest, FSTComponentLabelPathSegment);
    OrderedCode::WriteString(dest, segment);
  }
}

/**
 * Reads component labels and strings from the given key contents until it finds a component label
 * other that FSTComponentLabelPathSegment. All matched path segments are assembled into a resource
 * path and wrapped in an FSTDocumentKey.
 *
 * If the read is unsuccessful or the document key is invalid, returns NO, and changes none of its
 * arguments.
 *
 * If the read is successful, returns YES, contents will be updated to the next unread byte, and
 * value will be set to the decoded document key.
 */
BOOL ReadDocumentKey(Slice *contents, FSTDocumentKey *__strong *result) {
  Slice completeSegments = *contents;

  std::string segment;
  std::vector<std::string> path_segments;
  for (;;) {
    // Advance a temporary slice to avoid advancing contents into the next key component which may
    // not be a path segment.
    absl::string_view readPosition(completeSegments.data(), completeSegments.size());
    if (!ReadComponentLabelMatching(&readPosition, FSTComponentLabelPathSegment)) {
      break;
    }
    if (!OrderedCode::ReadString(&readPosition, &segment)) {
      return NO;
    }

    path_segments.push_back(std::move(segment));
    segment.clear();

    completeSegments = leveldb::Slice(readPosition.data(), readPosition.size());
  }

  ResourcePath path{std::move(path_segments)};
  if (path.size() > 0 && [FSTDocumentKey isDocumentKey:path]) {
    *contents = completeSegments;
    *result = [FSTDocumentKey keyWithPath:path];
    return YES;
  }

  return NO;
}

// Trivial shortcuts that make reading and writing components type-safe.

inline void WriteTerminator(std::string *dest) {
  OrderedCode::WriteSignedNumIncreasing(dest, FSTComponentLabelTerminator);
}

inline BOOL ReadTerminator(Slice *contents) {
  absl::string_view tmp(contents->data(), contents->size());
  BOOL result = ReadComponentLabelMatching(&tmp, FSTComponentLabelTerminator);
  *contents = leveldb::Slice(tmp.data(), tmp.size());
  return result;
}

inline void WriteTableName(std::string *dest, const char *tableName) {
  WriteLabeledString(dest, FSTComponentLabelTableName, tableName);
}

inline BOOL ReadTableNameMatching(Slice *contents, const char *expectedTableName) {
  return ReadLabeledStringMatching(contents, FSTComponentLabelTableName, expectedTableName);
}

}  // namespace

@implementation FSTLevelDBRemoteDocumentKey

+ (std::string)keyPrefix {
  std::string result;
  WriteTableName(&result, kRemoteDocumentsTable);
  return result;
}

+ (std::string)keyPrefixWithResourcePath:(const ResourcePath &)path {
  std::string result;
  WriteTableName(&result, kRemoteDocumentsTable);
  WriteResourcePath(&result, path);
  return result;
}

+ (std::string)keyWithDocumentKey:(FSTDocumentKey *)key {
  std::string result;
  WriteTableName(&result, kRemoteDocumentsTable);
  WriteResourcePath(&result, key.path);
  WriteTerminator(&result);
  return result;
}

- (BOOL)decodeKey:(StringView)key {
  _documentKey = nil;

  Slice contents = key;
  return ReadTableNameMatching(&contents, kRemoteDocumentsTable) &&
         ReadDocumentKey(&contents, &_documentKey) && ReadTerminator(&contents);
}

@end

NS_ASSUME_NONNULL_END
