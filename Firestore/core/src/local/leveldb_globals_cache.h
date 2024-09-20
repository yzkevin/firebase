/*
* Copyright 2024 Google LLC
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

#ifndef FIRESTORE_CORE_SRC_LOCAL_LEVELDB_GLOBALS_CACHE_H
#define FIRESTORE_CORE_SRC_LOCAL_LEVELDB_GLOBALS_CACHE_H

#include "Firestore/core/src/local/globals_cache.h"

namespace firebase {
namespace firestore {
namespace local {

class LevelDbPersistence;

class LevelDbGlobalsCache : public GlobalsCache {
 public:
  /** Creates a new bundle cache in the given LevelDB. */
  LevelDbGlobalsCache(LevelDbPersistence* db);

  /**
   * Gets session token.
   */
  ByteString GetSessionToken() const override;

  /**
   * Sets session token.
   */
  void SetSessionToken(const ByteString& session_token) override;


 private:
  // The LevelDbGlobalsCache is owned by LevelDbPersistence.
  LevelDbPersistence* db_ = nullptr;

};

}  // namespace local
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_LOCAL_LEVELDB_GLOBALS_CACHE_H
