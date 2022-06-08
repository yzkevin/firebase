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
#if COCOAPODS
  import GTMSessionFetcher
#else
  import GTMSessionFetcherCore
#endif

/**
 * A Task that lists the entries under a {@link StorageReference}
 */
internal class StorageListTask: StorageTask, StorageTaskManagement {
  private var fetcher: GTMSessionFetcher?
  private var fetcherCompletion: ((Data?, NSError?) -> Void)?
  private var completion: ((_: StorageListResult?, _: Error?) -> Void)?
  private let pageSize: Int64?
  private let previousPageToken: String?

  /**
   * Initializes a new List Task.
   *
   * To schedule the task, invoke `[FIRStorageListTask enqueue]`.
   *
   * @param reference The location to invoke List on.
   * @param service GTMSessionFetcherService to use for the RPC.
   * @param queue The queue to schedule the List operation on.
   * @param pageSize An optional pageSize, denoting the maximum size of the result set. If
   * set to `nil`, the backend will use the default page size.
   * @param previousPageToken An optional pageToken, used to resume a previous invocation.
   * @param completion The completion handler to be called with the FIRIMPLStorageListResult.
   */
  
  internal init(reference: FIRIMPLStorageReference,
                fetcherService: GTMSessionFetcherService,
                queue: DispatchQueue,
                pageSize: Int64?,
                previousPageToken: String?,
                completion: ((_: StorageListResult?, _: Error?) -> Void)?) {
    self.pageSize = pageSize
    self.previousPageToken = previousPageToken
    super.init(reference: reference, service: fetcherService, queue: queue)
    self.completion = completion
  }

  deinit {
    self.fetcher?.stopFetching()
  }

  /**
   * Prepares a task and begins execution.
   */
  internal func enqueue() {
    weak var weakSelf = self
    DispatchQueue.global(qos: .background).async {
      guard let strongSelf = weakSelf else {
        return
      }
      var queryParams = [String: String]()
      
      let prefix = strongSelf.reference.fullPath
      if prefix.count > 0 {
        queryParams["prefix"] = "\(prefix)/"
      }
      
      // Firebase Storage uses file system semantics and treats slashes as separators. GCS's List API
      // does not prescribe a separator, and hence we need to provide a slash as the delimiter.
      queryParams["delimiter"] = "/"
      
      // listAll() doesn't set a pageSize as this allows Firebase Storage to determine how many items
      // to return per page. This removes the need to backfill results if Firebase Storage filters
      // objects that are considered invalid (such as items with two consecutive slashes).
      if let pageSize = strongSelf.pageSize {
        queryParams["maxResults"] = "\(pageSize)"
      }

      if let previousPageToken = strongSelf.previousPageToken {
        queryParams["pageToken"] = previousPageToken
      }
      
      let root = strongSelf.reference.root()
      var request = StorageUtils.defaultRequestForReference(reference: root, queryParams: queryParams)
      
      request.httpMethod = "GET"
      request.timeoutInterval = strongSelf.reference.storage.maxOperationRetryTime

      let callback = strongSelf.completion
      strongSelf.completion = nil

      let fetcher = strongSelf.fetcherService.fetcher(with: request)
      fetcher.comment = "ListTask"
      strongSelf.fetcher = fetcher

      strongSelf.fetcherCompletion = { (data: Data?, error: NSError?) in
        if let error = error, self.error == nil {
          self.error = StorageErrorCode.error(withServerError: error, ref: strongSelf.reference)
        }
        guard let data = data else {
          fatalError("Internal Error: fetcherCompletion returned with nil data and nil error")
        }

        var listResult: StorageListResult?
        if let responseDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
          listResult = StorageListResult(with: responseDictionary, reference: self.reference)
        } else {
          self.error = StorageErrorCode.error(withInvalidRequest: data)
        }

        if let callback = callback {
          callback(listResult, self.error)
        }
        self.fetcherCompletion = nil
      }

      strongSelf.fetcher?.beginFetch { data, error in
        let strongSelf = weakSelf
        if let fetcherCompletion = strongSelf?.fetcherCompletion {
          fetcherCompletion(data, error as? NSError)
        }
      }
    }
  }
}
