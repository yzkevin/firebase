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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_LOCAL_MUTATION_QUEUE_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_LOCAL_MUTATION_QUEUE_H_

#if !defined(__OBJC__)
#error "For now, this file must only be included by ObjC source files."
#endif  // !defined(__OBJC__)

#import <Foundation/Foundation.h>

#include <vector>

#include "Firestore/core/src/firebase/firestore/model/document_key.h"
#include "Firestore/core/src/firebase/firestore/model/document_key_set.h"
#include "Firestore/core/src/firebase/firestore/model/types.h"

@class FIRTimestamp;
@class FSTMutation;
@class FSTMutationBatch;
@class FSTQuery;

NS_ASSUME_NONNULL_BEGIN

namespace firebase {
namespace firestore {
namespace local {

/** A queue of mutations to apply to the remote store. */
class MutationQueue {
 public:
  virtual ~MutationQueue() {
  }

  /** Returns true if this queue contains no mutation batches. */
  virtual bool IsEmpty() = 0;

  /** Acknowledges the given batch. */
  virtual void AcknowledgeBatch(FSTMutationBatch* batch,
          NSData* _Nullable stream_token) = 0;

  /** Creates a new mutation batch and adds it to this mutation queue. */
  virtual FSTMutationBatch* AddMutationBatch(FIRTimestamp* local_write_time,
          NSArray<FSTMutation*>* mutations) = 0;

  /**
   * Removes the given mutation batch from the queue. This is useful in two circumstances:
   *
   * + Removing applied mutations from the head of the queue
   * + Removing rejected mutations from anywhere in the queue
   */
  virtual void RemoveMutationBatch(FSTMutationBatch* batch) = 0;

  /** Gets all mutation batches in the mutation queue. */
  // TODO(mikelehen): PERF: Current consumer only needs mutated keys; if we can provide that
  // cheaply, we should replace this.
  virtual const std::vector<FSTMutationBatch*> AllMutationBatches() = 0;

  /**
   * Finds all mutation batches that could @em possibly affect the given document keys. Not all
   * mutations in a batch will necessarily affect each key, so when looping through the batches you'll
   * need to check that the mutation itself matches the key.
   *
   * Note that because of this requirement implementations are free to return mutation batches that
   * don't contain any of the given document keys at all if it's convenient.
   */
  // TODO(mcg): This should really return an iterator
  virtual std::vector<FSTMutationBatch*> AllMutationBatchesAffectingDocumentKeys(
          const model::DocumentKeySet& document_keys) = 0;

  /**
   * Finds all mutation batches that could @em possibly affect the given document key. Not all
   * mutations in a batch will necessarily affect the document key, so when looping through the
   * batch you'll need to check that the mutation itself matches the key.
   *
   * Note that because of this requirement implementations are free to return mutation batches that
   * don't contain the document key at all if it's convenient.
   */
  // TODO(mcg): This should really return an iterator
  virtual std::vector<FSTMutationBatch*> AllMutationBatchesAffectingDocumentKey(
          const model::DocumentKey& key) = 0;

  /**
   * Finds all mutation batches that could affect the results for the given query. Not all
   * mutations in a batch will necessarily affect the query, so when looping through the batch
   * you'll need to check that the mutation itself matches the query.
   *
   * Note that because of this requirement implementations are free to return mutation batches that
   * don't match the query at all if it's convenient.
   *
   * NOTE: A FSTPatchMutation does not need to include all fields in the query filter criteria in
   * order to be a match (but any fields it does contain do need to match).
   */
  // TODO(mikelehen): This should perhaps return an iterator, though I'm not sure we can avoid
  // loading them all in memory.
  virtual std::vector<FSTMutationBatch*> AllMutationBatchesAffectingQuery(
          FSTQuery* query) = 0;

  /** Loads the mutation batch with the given batchID. */
  virtual FSTMutationBatch* _Nullable LookupMutationBatch(model::BatchId batch_id) = 0;

  /**
   * Gets the first unacknowledged mutation batch after the passed in batchId in the mutation queue
   * or nil if empty.
   *
   * @param batchID The batch to search after, or kBatchIdUnknown for the first mutation in the
   * queue.
   *
   * @return the next mutation or nil if there wasn't one.
   */
  virtual FSTMutationBatch* _Nullable NextMutationBatchAfterBatchId(
          model::BatchId batch_id) = 0;

  /** Performs a consistency check, examining the mutation queue for any leaks, if possible. */
  virtual void PerformConsistencyCheck() = 0;

  /** Returns the current stream token for this mutation queue. */
  virtual NSData* _Nullable GetLastStreamToken() = 0;

  /** Sets the stream token for this mutation queue. */
  virtual void SetLastStreamToken(NSData* _Nullable stream_token) = 0;
};

}  // namespace local
}  // namespace firestore
}  // namespace firebase

NS_ASSUME_NONNULL_END

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_LOCAL_MUTATION_QUEUE_H_
