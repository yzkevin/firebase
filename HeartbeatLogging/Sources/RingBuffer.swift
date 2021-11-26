// Copyright 2021 Google LLC
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

/// <#Description#>
struct RingBuffer<Element>: Sequence {
  /// An array of heartbeats treated as a circular queue and intialized with a fixed capacity.
  private var circularQueue: [Element?]
  /// The current "tail" and insert point for the `circularQueue`.
  private var tailIndex: Int = 0

  /// Intializes a `RingBuffer` with a given `capacity`.
  /// - Parameter capacity: An `Int` representing the capacity.
  init(capacity: Int) {
    circularQueue = Array(repeating: nil, count: capacity)
  }

  /// Pushes an element to the back of the buffer, returning the element (`Element?`) that was overriten.
  /// - Parameter element: The element to push to the back of the buffer.
  /// - Returns: <#description#>
  /// - Complexity: O(1)
  @discardableResult
  mutating func push(_ element: Element) -> Element? {
    guard circularQueue.capacity > 0 else {
      // Do not append if `capacity` is less than or equal 0.
      return nil
    }

    defer {
      // Increment index, wrapping around to the start if needed.
      tailIndex += 1
      tailIndex %= circularQueue.count
    }

    let replaced = circularQueue[tailIndex]
    circularQueue[tailIndex] = element
    return replaced
  }

  func makeIterator() -> IndexingIterator<[Element]> {
    circularQueue
      .compactMap { $0 } // Remove `nil` elements.
      .makeIterator()
  }
}

// MARK: - Codable

extension RingBuffer: Codable where Element: Codable {}
