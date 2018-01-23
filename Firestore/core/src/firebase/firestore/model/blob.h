/*
 * Copyright 2018 Google
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

#ifndef FIRESTORE_CORE_INCLUDE_FIREBASE_FIRESTORE_BLOB_H_
#define FIRESTORE_CORE_INCLUDE_FIREBASE_FIRESTORE_BLOB_H_

#include <stdint.h>
#include <string.h>

namespace firebase {
namespace firestore {
namespace model {

/** Immutable class representing an array of bytes in Firestore. */
class Blob {
 public:
  Blob(const Blob& value);
  Blob(Blob&& value);
  ~Blob();

  /** Build a new Blob and copy the bytes from source. */
  static Blob CopyFrom(const uint8_t* source, size_t size);

  /** Build a new Blob and take the ownership of source. */
  static Blob MoveFrom(uint8_t* source, size_t size);

  const uint8_t* get() const {
    return buffer_;
  }

  size_t size() const {
    return size_;
  }

  Blob& operator=(const Blob& value);
  Blob& operator=(Blob&& value);

 private:
  Blob();

  uint8_t* buffer_;
  size_t size_;
};

/** Compares against another Blob. */
bool operator<(const Blob& lhs, const Blob& rhs);

inline bool operator>(const Blob& lhs, const Blob& rhs) {
  return rhs < lhs;
}

inline bool operator>=(const Blob& lhs, const Blob& rhs) {
  return !(lhs < rhs);
}

inline bool operator<=(const Blob& lhs, const Blob& rhs) {
  return !(lhs > rhs);
}

inline bool operator!=(const Blob& lhs, const Blob& rhs) {
  return lhs < rhs || lhs > rhs;
}

inline bool operator==(const Blob& lhs, const Blob& rhs) {
  return !(lhs != rhs);
}

}  // namespace model
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_INCLUDE_FIREBASE_FIRESTORE_BLOB_H_
