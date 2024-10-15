// Copyright 2024 Google LLC
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

import XCTest

@testable import FirebaseVertexAI

final class ProtoDateTests: XCTestCase {
  let decoder = JSONDecoder()

  // MARK: - Date Components Tests

  // A full date, with non-zero year, month, and day values.
  func testProtoDate_fullDate_dateComponents() {
    let year = 2024
    let month = 12
    let day = 31
    let protoDate = ProtoDate(year: year, month: month, day: day)

    let dateComponents = protoDate.dateComponents

    XCTAssertTrue(dateComponents.isValidDate)
    XCTAssertEqual(dateComponents.year, year)
    XCTAssertEqual(dateComponents.month, month)
    XCTAssertEqual(dateComponents.day, day)
  }

  // A month and day value, with a zero year, such as an anniversary.
  func testProtoDate_monthDay_dateComponents() {
    let month = 7
    let day = 1
    let protoDate = ProtoDate(year: nil, month: month, day: day)

    let dateComponents = protoDate.dateComponents

    XCTAssertTrue(dateComponents.isValidDate)
    XCTAssertNil(dateComponents.year)
    XCTAssertEqual(dateComponents.month, month)
    XCTAssertEqual(dateComponents.day, day)
  }

  // A year on its own, with zero month and day values.
  func testProtoDate_yearOnly_dateComponents() {
    let year = 2024
    let protoDate = ProtoDate(year: year, month: nil, day: nil)

    let dateComponents = protoDate.dateComponents

    XCTAssertTrue(dateComponents.isValidDate)
    XCTAssertEqual(dateComponents.year, year)
    XCTAssertNil(dateComponents.month)
    XCTAssertNil(dateComponents.day)
  }

  // A year and month value, with a zero day, such as a credit card expiration date
  func testProtoDate_yearMonth_dateComponents() {
    let year = 2024
    let month = 8
    let protoDate = ProtoDate(year: year, month: month, day: nil)

    let dateComponents = protoDate.dateComponents

    XCTAssertTrue(dateComponents.isValidDate)
    XCTAssertEqual(protoDate.year, year)
    XCTAssertEqual(protoDate.month, month)
    XCTAssertEqual(protoDate.day, nil)
  }

  // MARK: - Date Conversion Tests

  func testProtoDate_fullDate_asDate() throws {
    let protoDate = ProtoDate(year: 2024, month: 12, day: 31)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let expectedDate = try XCTUnwrap(dateFormatter.date(from: "2024-12-31"))

    let date = try XCTUnwrap(protoDate.asDate())

    XCTAssertEqual(date, expectedDate)
  }

  func testProtoDate_monthDay_asDate_throws() {
    let protoDate = ProtoDate(year: nil, month: 7, day: 1)

    do {
      _ = try protoDate.asDate()
    } catch let error as ProtoDate.DateConversionError {
      XCTAssertTrue(error.localizedDescription.contains("Missing a year"))
      return
    } catch {
      XCTFail("Expected \(ProtoDate.DateConversionError.self), got \(error).")
    }
    XCTFail("Expected an error but none thrown.")
  }

  func testProtoDate_yearOnly_asDate_throws() {
    let protoDate = ProtoDate(year: 2024, month: nil, day: nil)

    do {
      _ = try protoDate.asDate()
    } catch let error as ProtoDate.DateConversionError {
      XCTAssertTrue(error.localizedDescription.contains("Missing a month"))
      return
    } catch {
      XCTFail("Expected \(ProtoDate.DateConversionError.self), got \(error).")
    }
    XCTFail("Expected an error but none thrown.")
  }

  func testProtoDate_yearMonth_asDate_throws() {
    let protoDate = ProtoDate(year: 2024, month: 8, day: nil)

    do {
      _ = try protoDate.asDate()
    } catch let error as ProtoDate.DateConversionError {
      XCTAssertTrue(error.localizedDescription.contains("Missing a day"))
      return
    } catch {
      XCTFail("Expected \(ProtoDate.DateConversionError.self), got \(error).")
    }
    XCTFail("Expected an error but none thrown.")
  }

  func testProtoDate_invalidDate_asDate_throws() {
    // Reminder: Only 30 days in November
    let protoDate = ProtoDate(year: 2024, month: 11, day: 31)

    do {
      _ = try protoDate.asDate()
    } catch let error as ProtoDate.DateConversionError {
      XCTAssertTrue(error.localizedDescription.contains("Invalid date"))
      return
    } catch {
      XCTFail("Expected \(ProtoDate.DateConversionError.self), got \(error).")
    }
    XCTFail("Expected an error but none thrown.")
  }

  func testProtoDate_empty_asDate_throws() {
    let protoDate = ProtoDate(year: nil, month: nil, day: nil)

    do {
      _ = try protoDate.asDate()
    } catch let error as ProtoDate.DateConversionError {
      XCTAssertTrue(error.localizedDescription.contains("Missing a year"))
      return
    } catch {
      XCTFail("Expected \(ProtoDate.DateConversionError.self), got \(error).")
    }
    XCTFail("Expected an error but none thrown.")
  }

  // MARK: - Decoding Tests

  func testDecodeProtoDate_fullDate() throws {
    let json = """
    {
      "year" : 2024,
      "month" : 12,
      "day" : 31
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertEqual(protoDate.year, 2024)
    XCTAssertEqual(protoDate.month, 12)
    XCTAssertEqual(protoDate.day, 31)
  }

  func testDecodeProtoDate_monthDay() throws {
    let json = """
    {
      "year": 0,
      "month" : 12,
      "day" : 31
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertNil(protoDate.year)
    XCTAssertEqual(protoDate.month, 12)
    XCTAssertEqual(protoDate.day, 31)
  }

  func testDecodeProtoDate_monthDay_defaultsOmitted() throws {
    let json = """
    {
      "month" : 12,
      "day" : 31
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertNil(protoDate.year)
    XCTAssertEqual(protoDate.month, 12)
    XCTAssertEqual(protoDate.day, 31)
  }

  func testDecodeProtoDate_yearOnly() throws {
    let json = """
    {
      "year": 2024,
      "month" : 0,
      "day" : 0
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertEqual(protoDate.year, 2024)
    XCTAssertNil(protoDate.month)
    XCTAssertNil(protoDate.day)
  }

  func testDecodeProtoDate_yearOnly_defaultsOmitted() throws {
    let json = """
    {
      "year": 2024
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertEqual(protoDate.year, 2024)
    XCTAssertNil(protoDate.month)
    XCTAssertNil(protoDate.day)
  }

  func testDecodeProtoDate_yearMonth() throws {
    let json = """
    {
      "year": 2024,
      "month" : 12,
      "day": 0
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertEqual(protoDate.year, 2024)
    XCTAssertEqual(protoDate.month, 12)
    XCTAssertNil(protoDate.day)
  }

  func testDecodeProtoDate_yearMonth_defaultsOmitted() throws {
    let json = """
    {
      "year": 2024,
      "month" : 12
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    let protoDate = try decoder.decode(ProtoDate.self, from: jsonData)

    XCTAssertEqual(protoDate.year, 2024)
    XCTAssertEqual(protoDate.month, 12)
    XCTAssertNil(protoDate.day)
  }

  func testDecodeProtoDate_emptyDate_throws() throws {
    let json = """
    {
      "year": 0,
      "month" : 0,
      "day": 0
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    do {
      _ = try decoder.decode(ProtoDate.self, from: jsonData)
    } catch let DecodingError.dataCorrupted(context) {
      XCTAssertEqual(
        context.codingPath as? [ProtoDate.CodingKeys],
        [ProtoDate.CodingKeys.year, ProtoDate.CodingKeys.month, ProtoDate.CodingKeys.day]
      )
      XCTAssertTrue(context.debugDescription.contains("Invalid date"))
      return
    }
    XCTFail("Expected a DecodingError.")
  }

  func testDecodeProtoDate_emptyDate_defaultsOmitted_throws() throws {
    let json = "{}"
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    do {
      _ = try decoder.decode(ProtoDate.self, from: jsonData)
    } catch let DecodingError.dataCorrupted(context) {
      XCTAssertEqual(
        context.codingPath as? [ProtoDate.CodingKeys],
        [ProtoDate.CodingKeys.year, ProtoDate.CodingKeys.month, ProtoDate.CodingKeys.day]
      )
      XCTAssertTrue(context.debugDescription.contains("Invalid date"))
      return
    }
    XCTFail("Expected a DecodingError.")
  }

  func testDecodeProtoDate_invalidYear_throws() throws {
    let json = """
    {
      "year" : -2024,
      "month" : 12,
      "day" : 31
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    do {
      _ = try decoder.decode(ProtoDate.self, from: jsonData)
    } catch let DecodingError.dataCorrupted(context) {
      XCTAssertEqual(context.codingPath as? [ProtoDate.CodingKeys], [ProtoDate.CodingKeys.year])
      XCTAssertTrue(context.debugDescription.contains("Invalid year"))
      return
    }
    XCTFail("Expected a DecodingError.")
  }

  func testDecodeProtoDate_invalidMonth_throws() throws {
    let json = """
    {
      "year" : 2024,
      "month" : 13,
      "day" : 31
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    do {
      _ = try decoder.decode(ProtoDate.self, from: jsonData)
    } catch let DecodingError.dataCorrupted(context) {
      XCTAssertEqual(context.codingPath as? [ProtoDate.CodingKeys], [ProtoDate.CodingKeys.month])
      XCTAssertTrue(context.debugDescription.contains("Invalid month"))
      return
    }
    XCTFail("Expected a DecodingError.")
  }

  func testDecodeProtoDate_invalidDay_throws() throws {
    let json = """
    {
      "year" : 2024,
      "month" : 12,
      "day" : 32
    }
    """
    let jsonData = try XCTUnwrap(json.data(using: .utf8))

    do {
      _ = try decoder.decode(ProtoDate.self, from: jsonData)
    } catch let DecodingError.dataCorrupted(context) {
      XCTAssertEqual(context.codingPath as? [ProtoDate.CodingKeys], [ProtoDate.CodingKeys.day])
      XCTAssertTrue(context.debugDescription.contains("Invalid day"))
      return
    }
    XCTFail("Expected a DecodingError.")
  }
}