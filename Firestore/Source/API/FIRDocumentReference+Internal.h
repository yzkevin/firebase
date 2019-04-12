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

#import "FIRDocumentReference.h"

#include <memory>

#include "Firestore/core/src/firebase/firestore/api/document_reference.h"
#include "Firestore/core/src/firebase/firestore/model/document_key.h"
#include "Firestore/core/src/firebase/firestore/model/resource_path.h"

namespace api = firebase::firestore::api;
namespace model = firebase::firestore::model;

NS_ASSUME_NONNULL_BEGIN

@interface FIRDocumentReference (/* Init */)

- (instancetype)initWithReference:(api::DocumentReference &&)reference NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPath:(model::ResourcePath)path
                   firestore:(std::shared_ptr<api::Firestore>)firestore;

- (instancetype)initWithKey:(model::DocumentKey)key
                  firestore:(std::shared_ptr<api::Firestore>)firestore;

@end

/** Internal FIRDocumentReference API we don't want exposed in our public header files. */
@interface FIRDocumentReference (Internal)

- (const model::DocumentKey &)key;

@end

NS_ASSUME_NONNULL_END
