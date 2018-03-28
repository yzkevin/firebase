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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_IMMUTABLE_ARRAY_SORTED_MAP_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_IMMUTABLE_ARRAY_SORTED_MAP_H_

#include <algorithm>
#include <array>
#include <cassert>
#include <functional>
#include <memory>
#include <utility>

#include "Firestore/core/src/firebase/firestore/immutable/map_entry.h"
#include "Firestore/core/src/firebase/firestore/immutable/sorted_map_base.h"
#include "Firestore/core/src/firebase/firestore/util/comparison.h"
#include "Firestore/core/src/firebase/firestore/util/firebase_assert.h"

namespace firebase {
namespace firestore {
namespace immutable {
namespace impl {

/**
 * A bounded-size array that allocates its contents directly in itself. This
 * saves a heap allocation when compared with std::vector (though std::vector
 * can resize itself while FixedArray cannot).
 *
 * Unlike std::array, FixedArray keeps track of its size and grows up to the
 * fixed_size limit. Inserting more elements than fixed_size will trigger an
 * assertion failure.
 *
 * ArraySortedMap does not actually contain its array: it contains a shared_ptr
 * to a FixedArray.
 *
 * @tparam T The type of an element in the array.
 * @tparam fixed_size the fixed size to use in creating the FixedArray.
 */
template <typename T, SortedMapBase::size_type fixed_size>
class FixedArray {
 public:
  using size_type = SortedMapBase::size_type;
  using array_type = std::array<T, fixed_size>;
  using iterator = typename array_type::iterator;
  using const_iterator = typename array_type::const_iterator;

  FixedArray() {
  }

  template <typename SourceIterator>
  FixedArray(SourceIterator src_begin, SourceIterator src_end) {
    append(src_begin, src_end);
  }

  /**
   * Appends to this array, copying from the given src_begin up to but not
   * including the src_end.
   */
  template <typename SourceIterator>
  void append(SourceIterator src_begin, SourceIterator src_end) {
    size_type appending = static_cast<size_type>(src_end - src_begin);
    size_type new_size = size_ + appending;
    FIREBASE_ASSERT(new_size <= fixed_size);

    std::copy(src_begin, src_end, end());
    size_ = new_size;
  }

  /**
   * Appends a single value to the array.
   */
  void append(T&& value) {
    size_type new_size = size_ + 1;
    FIREBASE_ASSERT(new_size <= fixed_size);

    *end() = std::move(value);
    size_ = new_size;
  }

  const_iterator begin() const {
    return contents_.begin();
  }

  const_iterator end() const {
    return begin() + size_;
  }

  size_type size() const {
    return size_;
  }

 private:
  iterator begin() {
    return contents_.begin();
  }

  iterator end() {
    return begin() + size_;
  }

  array_type contents_;
  size_type size_ = 0;
};

/**
 * ArraySortedMap is a value type containing a map. It is immutable, but has
 * methods to efficiently create new maps that are mutations of it.
 */
template <typename K, typename V, typename C = util::Comparator<K>>
class ArraySortedMap : public SortedMapBase {
 public:
  using key_comparator_type = KeyComparator<K, V, C>;

  /**
   * The type of the entries stored in the map.
   */
  using value_type = std::pair<K, V>;

  /**
   * The type of the fixed-size array containing entries of value_type.
   */
  using array_type = FixedArray<value_type, kFixedSize>;
  using const_iterator = typename array_type::const_iterator;

  using array_pointer = std::shared_ptr<const array_type>;

  /**
   * Creates an empty ArraySortedMap.
   */
  explicit ArraySortedMap(const C& comparator = C())
      : array_{EmptyArray()}, key_comparator_{comparator} {
  }

  /**
   * Creates an ArraySortedMap containing the given entries.
   */
  ArraySortedMap(std::initializer_list<value_type> entries,
                 const C& comparator = C())
      : array_{std::make_shared<array_type>(entries.begin(), entries.end())},
        key_comparator_{comparator} {
  }

  /**
   * Creates a new map identical to this one, but with a key-value pair added or
   * updated.
   *
   * @param key The key to insert/update.
   * @param value The value to associate with the key.
   * @return A new dictionary with the added/updated value.
   */
  ArraySortedMap insert(const K& key, const V& value) const {
    const_iterator current_end = end();
    const_iterator pos = LowerBound(key);
    bool replacing_entry = false;

    if (pos != current_end) {
      // LowerBound found an entry where pos->first >= pair.first. Reversing the
      // argument order here tests pair.first < pos->first.
      replacing_entry = !key_comparator_(key, *pos);
      if (replacing_entry && value == pos->second) {
        return *this;
      }
    }

    // Copy the segment before the found position. If not found, this is
    // everything.
    auto copy = std::make_shared<array_type>(begin(), pos);

    // Copy the value to be inserted.
    copy->append({key, value});

    if (replacing_entry) {
      // Skip the thing at pos because it compares the same as the pair above.
      copy->append(pos + 1, current_end);
    } else {
      copy->append(pos, current_end);
    }
    return wrap(copy);
  }

  /**
   * Creates a new map identical to this one, but with a key removed from it.
   *
   * @param key The key to remove.
   * @return A new dictionary without that value.
   */
  ArraySortedMap erase(const K& key) const {
    const_iterator current_end = end();
    const_iterator pos = find(key);
    if (pos == current_end) {
      return *this;
    } else if (size() <= 1) {
      // If the key was found and it's the last entry, removing it would make
      // the result empty.
      return wrap(EmptyArray());
    } else {
      auto copy = std::make_shared<array_type>(begin(), pos);
      copy->append(pos + 1, current_end);
      return wrap(copy);
    }
  }

  /**
   * Finds a value in the map.
   *
   * @param key The key to look up.
   * @return An iterator pointing to the entry containing the key, or end() if
   *     not found.
   */
  const_iterator find(const K& key) const {
    const_iterator not_found = end();
    const_iterator lower_bound = LowerBound(key);
    if (lower_bound != not_found && !key_comparator_(key, *lower_bound)) {
      return lower_bound;
    } else {
      return not_found;
    }
  }

  // TODO(wilhuff): indexof

  const key_comparator_type& comparator() const {
    return key_comparator_;
  }

  /** Returns true if the map contains no elements. */
  bool empty() const {
    return size() == 0;
  }

  /** Returns the number of items in this map. */
  size_type size() const {
    return array_->size();
  }

  /**
   * Returns an iterator pointing to the first entry in the map. If there are
   * no entries in the map, begin() == end().
   */
  const_iterator begin() const {
    return array_->begin();
  }

  /**
   * Returns an iterator pointing past the last entry in the map.
   */
  const_iterator end() const {
    return array_->end();
  }

 private:
  static array_pointer EmptyArray() {
    static const array_pointer kEmptyArray =
        std::make_shared<const array_type>();
    return kEmptyArray;
  }

  ArraySortedMap(const array_pointer& array,
                 const key_comparator_type& key_comparator) noexcept
      : array_{array}, key_comparator_{key_comparator} {
  }

  ArraySortedMap wrap(const array_pointer& array) const noexcept {
    return ArraySortedMap{array, key_comparator_};
  }

  const_iterator LowerBound(const K& key) const {
    return std::lower_bound(begin(), end(), key, key_comparator_);
  }

  array_pointer array_;
  key_comparator_type key_comparator_;
};

}  // namespace impl
}  // namespace immutable
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_IMMUTABLE_ARRAY_SORTED_MAP_H_
