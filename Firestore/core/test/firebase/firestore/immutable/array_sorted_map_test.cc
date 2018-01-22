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

#include "Firestore/core/src/firebase/firestore/immutable/array_sorted_map.h"

#include "gtest/gtest.h"

namespace firebase {
namespace firestore {
namespace immutable {

typedef ArraySortedMap<int, int> IntMap;
constexpr ArraySortedMapBase::size_type kFixedSize =
    ArraySortedMapBase::kFixedSize;

template <typename K, typename V>
testing::AssertionResult NotFound(const ArraySortedMap<K, V>& set,
                                  const K& key) {
  auto found = set.find(key);
  if (found == set.end()) {
    return testing::AssertionSuccess();
  } else {
    return testing::AssertionFailure()
           << "Should not have found (" << found->first << ", " << found->second
           << ") @ " << found;
  }
}

template <typename K, typename V>
testing::AssertionResult Found(const ArraySortedMap<K, V>& map,
                               const K& key,
                               const V& expected) {
  auto found = map.find(key);
  if (found == map.end()) {
    return testing::AssertionFailure() << "Did not find key " << key;
  }
  if (found->second == expected) {
    return testing::AssertionSuccess();
  } else {
    return testing::AssertionFailure() << "Found entry was (" << found->first
                                       << ", " << found->second << ")";
  }
}

TEST(ArraySortedMap, SearchForSpecificKey) {
  IntMap map{{1, 3}, {2, 4}};

  ASSERT_TRUE(Found(map, 1, 3));
  ASSERT_TRUE(Found(map, 2, 4));
  ASSERT_TRUE(NotFound(map, 3));
}

TEST(ArraySortedMap, RemoveKeyValuePair) {
  IntMap map{{1, 3}, {2, 4}};

  IntMap new_set = map.erase(1);
  ASSERT_TRUE(Found(new_set, 2, 4));
  ASSERT_TRUE(NotFound(new_set, 1));

  // Make sure the original one is not mutated
  ASSERT_TRUE(Found(map, 1, 3));
  ASSERT_TRUE(Found(map, 2, 4));
}

TEST(ArraySortedMap, MoreRemovals) {
  IntMap map = IntMap()
                   .insert(1, 1)
                   .insert(50, 50)
                   .insert(3, 3)
                   .insert(4, 4)
                   .insert(7, 7)
                   .insert(9, 9)
                   .insert(1, 20)
                   .insert(18, 18)
                   .insert(3, 2)
                   .insert(4, 71)
                   .insert(7, 42)
                   .insert(9, 88);

  ASSERT_TRUE(Found(map, 7, 42));
  ASSERT_TRUE(Found(map, 3, 2));
  ASSERT_TRUE(Found(map, 1, 20));

  IntMap s1 = map.erase(7);
  IntMap s2 = map.erase(3);
  IntMap s3 = map.erase(1);

  ASSERT_TRUE(NotFound(s1, 7));
  ASSERT_TRUE(Found(s1, 3, 2));
  ASSERT_TRUE(Found(s1, 1, 20));

  ASSERT_TRUE(Found(s2, 7, 42));
  ASSERT_TRUE(NotFound(s2, 3));
  ASSERT_TRUE(Found(s2, 1, 20));

  ASSERT_TRUE(Found(s3, 7, 42));
  ASSERT_TRUE(Found(s3, 3, 2));
  ASSERT_TRUE(NotFound(s3, 1));
}

TEST(ArraySortedMap, RemoveMiddleBug) {
  IntMap map{{1, 1}, {2, 2}, {3, 3}};
  ASSERT_TRUE(Found(map, 1, 1));
  ASSERT_TRUE(Found(map, 2, 2));
  ASSERT_TRUE(Found(map, 3, 3));

  IntMap s1 = map.erase(2);
  ASSERT_TRUE(Found(s1, 1, 1));
  ASSERT_TRUE(NotFound(s1, 2));
  ASSERT_TRUE(Found(s1, 3, 3));
}

TEST(ArraySortedMap, Increasing) {
  int total = static_cast<int>(kFixedSize);
  IntMap map;

  for (int i = 0; i < total; i++) {
    map = map.insert(i, i);
  }
  ASSERT_EQ(kFixedSize, map.size());

  for (int i = 0; i < total; i++) {
    map = map.erase(i);
  }
  ASSERT_EQ(0u, map.size());
}

TEST(ArraySortedMap, Override) {
  IntMap map = IntMap().insert(10, 10).insert(10, 8);

  ASSERT_TRUE(Found(map, 10, 8));
}

TEST(ArraySortedMap, Empty) {
  IntMap map = IntMap().insert(10, 10).erase(10);
  EXPECT_TRUE(map.empty());
  EXPECT_EQ(0u, map.size());
  EXPECT_TRUE(NotFound(map, 1));
  EXPECT_TRUE(NotFound(map, 10));
}

TEST(ArraySortedMap, EmptyGet) {
  IntMap map;
  EXPECT_TRUE(NotFound(map, 10));
}

TEST(ArraySortedMap, EmptySize) {
  IntMap map;
  EXPECT_TRUE(map.empty());
  EXPECT_EQ(0u, map.size());
}

TEST(ArraySortedMap, EmptyRemoval) {
  IntMap map;
  IntMap new_map = map.erase(1);
  EXPECT_TRUE(new_map.empty());
  EXPECT_EQ(0u, new_map.size());
  EXPECT_TRUE(NotFound(new_map, 1));
}

TEST(ArraySortedMap, AvoidsCopying) {
  IntMap map;

  // Verify that emplacing a pair does not copy.
  IntMap inserted = map.insert(10, 20);
  auto found = inserted.find(10);
  ASSERT_NE(found, inserted.end());
  EXPECT_EQ(20, found->second);

  // Verify that inserting something with equal keys and values just returns
  // this.
  IntMap duped = inserted.insert(10, 20);
  auto duped_found = duped.find(10);

  // If everything worked correctly, the backing array should not have been
  // copied and the pointer to the entry with 10 as key should be the same.
  EXPECT_EQ(found, duped_found);
}

}  // namespace immutable
}  // namespace firestore
}  // namespace firebase
