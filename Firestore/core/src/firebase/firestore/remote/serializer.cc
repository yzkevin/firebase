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

#include "Firestore/core/src/firebase/firestore/remote/serializer.h"

#include <pb_decode.h>
#include <pb_encode.h>

#include <map>
#include <string>
#include <utility>

#include "Firestore/core/src/firebase/firestore/util/firebase_assert.h"

namespace firebase {
namespace firestore {
namespace remote {

using firebase::firestore::model::FieldValue;

namespace {

void EncodeObject(pb_ostream_t* stream,
                  const std::map<std::string, FieldValue>& object_value);

std::map<std::string, FieldValue> DecodeObject(pb_istream_t* stream);

/**
 * Note that (despite the value parameter type) this works for bool, enum,
 * int32, int64, uint32 and uint64 proto field types.
 *
 * Note: This is not expected to be called direclty, but rather only via the
 * other Encode* methods (i.e. EncodeBool, EncodeLong, etc)
 *
 * @param value The value to encode, represented as a uint64_t.
 */
void EncodeVarint(pb_ostream_t* stream, uint64_t value) {
  bool status = pb_encode_varint(stream, value);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
}

/**
 * Note that (despite the return type) this works for bool, enum, int32, int64,
 * uint32 and uint64 proto field types.
 *
 * Note: This is not expected to be called direclty, but rather only via the
 * other Decode* methods (i.e. DecodeBool, DecodeLong, etc)
 *
 * @return The decoded varint as a uint64_t.
 */
uint64_t DecodeVarint(pb_istream_t* stream) {
  uint64_t varint_value;
  bool status = pb_decode_varint(stream, &varint_value);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
  return varint_value;
}

void EncodeNull(pb_ostream_t* stream) {
  return EncodeVarint(stream, google_protobuf_NullValue_NULL_VALUE);
}

void DecodeNull(pb_istream_t* stream) {
  uint64_t varint = DecodeVarint(stream);
  if (varint != google_protobuf_NullValue_NULL_VALUE) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
}

void EncodeBool(pb_ostream_t* stream, bool bool_value) {
  return EncodeVarint(stream, bool_value);
}

bool DecodeBool(pb_istream_t* stream) {
  uint64_t varint = DecodeVarint(stream);
  switch (varint) {
    case 0:
      return false;
    case 1:
      return true;
    default:
      // TODO(rsgowman): figure out error handling
      abort();
  }
}

void EncodeInteger(pb_ostream_t* stream, int64_t integer_value) {
  return EncodeVarint(stream, integer_value);
}

int64_t DecodeInteger(pb_istream_t* stream) {
  return DecodeVarint(stream);
}

void EncodeString(pb_ostream_t* stream, const std::string& string_value) {
  bool status = pb_encode_string(
      stream, reinterpret_cast<const pb_byte_t*>(string_value.c_str()),
      string_value.length());
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
}

std::string DecodeString(pb_istream_t* stream) {
  pb_istream_t substream;
  bool status = pb_make_string_substream(stream, &substream);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  std::string result(substream.bytes_left, '\0');
  status = pb_read(&substream, reinterpret_cast<pb_byte_t*>(&result[0]),
                   substream.bytes_left);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  // NB: future versions of nanopb read the remaining characters out of the
  // substream (and return false if that fails) as an additional safety
  // check within pb_close_string_substream. Unfortunately, that's not present
  // in the current version (0.38).  We'll make a stronger assertion and check
  // to make sure there *are* no remaining characters in the substream.
  if (substream.bytes_left != 0) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  pb_close_string_substream(stream, &substream);

  return result;
}

// Named '..Impl' so as to not conflict with Serializer::EncodeFieldValue.
// TODO(rsgowman): Refactor to use a helper class that wraps the stream struct.
// This will help with error handling, and should eliminate the issue of two
// 'EncodeFieldValue' methods.
void EncodeFieldValueImpl(pb_ostream_t* stream, const FieldValue& field_value) {
  // TODO(rsgowman): some refactoring is in order... but will wait until after a
  // non-varint, non-fixed-size (i.e. string) type is present before doing so.
  bool status = false;
  switch (field_value.type()) {
    case FieldValue::Type::Null:
      status = pb_encode_tag(stream, PB_WT_VARINT,
                             google_firestore_v1beta1_Value_null_value_tag);
      if (!status) {
        // TODO(rsgowman): figure out error handling
        abort();
      }
      EncodeNull(stream);
      break;

    case FieldValue::Type::Boolean:
      status = pb_encode_tag(stream, PB_WT_VARINT,
                             google_firestore_v1beta1_Value_boolean_value_tag);
      if (!status) {
        // TODO(rsgowman): figure out error handling
        abort();
      }
      EncodeBool(stream, field_value.boolean_value());
      break;

    case FieldValue::Type::Integer:
      status = pb_encode_tag(stream, PB_WT_VARINT,
                             google_firestore_v1beta1_Value_integer_value_tag);
      if (!status) {
        // TODO(rsgowman): figure out error handling
        abort();
      }
      EncodeInteger(stream, field_value.integer_value());
      break;

    case FieldValue::Type::String:
      status = pb_encode_tag(stream, PB_WT_STRING,
                             google_firestore_v1beta1_Value_string_value_tag);
      if (!status) {
        // TODO(rsgowman): figure out error handling
        abort();
      }
      EncodeString(stream, field_value.string_value());
      break;

    case FieldValue::Type::Object:
      // NB: submessages use a wiretype of PB_WT_STRING
      status = pb_encode_tag(stream, PB_WT_STRING,
                             google_firestore_v1beta1_Value_map_value_tag);
      if (!status) {
        // TODO(rsgowman): figure out error handling
        abort();
      }
      EncodeObject(stream, field_value.object_value());
      break;

    default:
      // TODO(rsgowman): implement the other types
      abort();
  }
}

FieldValue DecodeFieldValueImpl(pb_istream_t* stream) {
  pb_wire_type_t wire_type;
  uint32_t tag;
  bool eof;
  bool status = pb_decode_tag(stream, &wire_type, &tag, &eof);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  // Ensure the tag matches the wire type
  // TODO(rsgowman): figure out error handling
  switch (tag) {
    case google_firestore_v1beta1_Value_null_value_tag:
    case google_firestore_v1beta1_Value_boolean_value_tag:
    case google_firestore_v1beta1_Value_integer_value_tag:
      if (wire_type != PB_WT_VARINT) {
        abort();
      }
      break;

    case google_firestore_v1beta1_Value_string_value_tag:
    case google_firestore_v1beta1_Value_map_value_tag:
      if (wire_type != PB_WT_STRING) {
        abort();
      }
      break;

    default:
      abort();
  }

  switch (tag) {
    case google_firestore_v1beta1_Value_null_value_tag:
      DecodeNull(stream);
      return FieldValue::NullValue();
    case google_firestore_v1beta1_Value_boolean_value_tag:
      return FieldValue::BooleanValue(DecodeBool(stream));
    case google_firestore_v1beta1_Value_integer_value_tag:
      return FieldValue::IntegerValue(DecodeInteger(stream));
    case google_firestore_v1beta1_Value_string_value_tag:
      return FieldValue::StringValue(DecodeString(stream));
    case google_firestore_v1beta1_Value_map_value_tag:
      return FieldValue::ObjectValue(DecodeObject(stream));

    default:
      // TODO(rsgowman): figure out error handling
      abort();
  }
}

/**
 * Encodes a FieldValue *and* its length.
 *
 * When encoding a top level message, protobuf doesn't include the length (since
 * you can get that already from the length of the binary output.) But when
 * encoding a sub/nested message, you must include the length in the
 * serialization.
 *
 * Call this method when encoding a non top level FieldValue. Otherwise call
 * EncodeFieldValue[Impl].
 */
void EncodeNestedFieldValue(pb_ostream_t* stream,
                            const FieldValue& field_value) {
  // Implementation note: This is roughly modeled on pb_encode_delimited (which
  // is actually pb_encode_submessage), adjusted to account for the oneof in
  // FieldValue.

  // First calculate the message size using a non-writing substream.
  pb_ostream_t substream = PB_OSTREAM_SIZING;
  EncodeFieldValueImpl(&substream, field_value);
  size_t size = substream.bytes_written;

  // Write out the size to the output stream.
  EncodeVarint(stream, size);

  // If stream is itself a sizing stream, then we don't need to actually parse
  // field_value a second time; just update the bytes_written via a call to
  // pb_write. (If we try to write the contents into a sizing stream, it'll
  // fail since sizing streams don't actually have any buffer space.)
  if (stream->callback == NULL) {
    bool status = pb_write(stream, NULL, size);
    if (!status) {
      // TODO(rsgowman): figure out error handling
      abort();
    }
    return;
  }

  // Ensure the output stream has enough space
  if (stream->bytes_written + size > stream->max_size) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  // Use a substream to verify that a callback doesn't write more than what it
  // did the first time. (Use an initializer rather than setting fields
  // individually like nanopb does. This gives us a *chance* of noticing if
  // nanopb adds new fields.)
  substream = {stream->callback, stream->state, /*max_size=*/size,
               /*bytes_written=*/0, /*errmsg=*/NULL};

  EncodeFieldValueImpl(&substream, field_value);
  stream->bytes_written += substream.bytes_written;
  stream->state = substream.state;
  stream->errmsg = substream.errmsg;

  if (substream.bytes_written != size) {
    // submsg size changed
    // TODO(rsgowman): figure out error handling
    abort();
  }
}

FieldValue DecodeSubFieldValue(pb_istream_t* stream) {
  // Implementation note: This is roughly modeled on pb_decode_delimited,
  // adjusted to account for the oneof in FieldValue.
  pb_istream_t substream;
  bool status = pb_make_string_substream(stream, &substream);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  FieldValue fv = DecodeFieldValueImpl(&substream);

  // NB: future versions of nanopb read the remaining characters out of the
  // substream (and return false if that fails) as an additional safety
  // check within pb_close_string_substream. Unfortunately, that's not present
  // in the current version (0.38).  We'll make a stronger assertion and check
  // to make sure there *are* no remaining characters in the substream.
  if (substream.bytes_left != 0) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
  pb_close_string_substream(stream, &substream);

  return fv;
}

/**
 * Encodes a 'FieldsEntry' object, within a FieldValue's map_value type.
 *
 * In protobuf, maps are implemented as a repeated set of key/values. For
 * instance, this:
 *   message Foo {
 *     map<string, Value> fields = 1;
 *   }
 * would be encoded (in proto text format) as:
 *   {
 *     fields: {key:"key string 1", value:{<Value message here>}}
 *     fields: {key:"key string 2", value:{<Value message here>}}
 *     ...
 *   }
 *
 * This method encodes an individual entry from that list. It is expected that
 * this method will be called once for each entry in the map.
 *
 * @param kv The individual key/value pair to encode.
 */
void EncodeFieldsEntry(pb_ostream_t* stream,
                       const std::pair<std::string, FieldValue>& kv) {
  // Encode the key (string)
  bool status =
      pb_encode_tag(stream, PB_WT_STRING,
                    google_firestore_v1beta1_MapValue_FieldsEntry_key_tag);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
  EncodeString(stream, kv.first);

  // Encode the value (FieldValue)
  status =
      pb_encode_tag(stream, PB_WT_STRING,
                    google_firestore_v1beta1_MapValue_FieldsEntry_value_tag);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
  EncodeNestedFieldValue(stream, kv.second);
}

std::pair<std::string, FieldValue> DecodeFieldsEntry(pb_istream_t* stream) {
  pb_wire_type_t wire_type;
  uint32_t tag;
  bool eof;
  bool status = pb_decode_tag(stream, &wire_type, &tag, &eof);
  // TODO(rsgowman): figure out error handling: We can do better than a failed
  // assertion.
  FIREBASE_ASSERT(tag == google_firestore_v1beta1_MapValue_FieldsEntry_key_tag);
  FIREBASE_ASSERT(wire_type == PB_WT_STRING);
  FIREBASE_ASSERT(!eof);
  FIREBASE_ASSERT(status);
  std::string key = DecodeString(stream);

  status = pb_decode_tag(stream, &wire_type, &tag, &eof);
  FIREBASE_ASSERT(tag ==
                  google_firestore_v1beta1_MapValue_FieldsEntry_value_tag);
  // NB: PB_WT_STRING is used for submessages too.
  FIREBASE_ASSERT(wire_type == PB_WT_STRING);
  FIREBASE_ASSERT(!eof);
  FIREBASE_ASSERT(status);

  FieldValue value = DecodeSubFieldValue(stream);

  return {key, value};
}

void EncodeObject(pb_ostream_t* stream,
                  const std::map<std::string, FieldValue>& object_value) {
  google_firestore_v1beta1_MapValue map_value =
      google_firestore_v1beta1_MapValue_init_zero;
  // NB: c-style callbacks can't use *capturing* lambdas, so we'll pass in the
  // object_value via the arg field (and therefore need to do a bunch of
  // casting).
  map_value.fields.funcs.encode = [](pb_ostream_t* stream, const pb_field_t*,
                                     void* const* arg) -> bool {
    auto& object_value =
        *static_cast<const std::map<std::string, FieldValue>*>(*arg);

    // Encode each FieldsEntry (i.e. key-value pair.)
    for (const auto& kv : object_value) {
      bool status =
          pb_encode_tag(stream, PB_WT_STRING,
                        google_firestore_v1beta1_MapValue_FieldsEntry_key_tag);
      if (!status) {
        // TODO(rsgowman): figure out error handling
        abort();
      }

      // Calculate the size of this FieldsEntry using a non-writing substream.
      pb_ostream_t sizing_stream = PB_OSTREAM_SIZING;
      EncodeFieldsEntry(&sizing_stream, kv);
      size_t size = sizing_stream.bytes_written;
      // Write out the size to the output stream.
      EncodeVarint(stream, size);

      EncodeFieldsEntry(stream, kv);
    }

    return true;
  };
  map_value.fields.arg =
      const_cast<std::map<std::string, FieldValue>*>(&object_value);

  bool status = pb_encode_delimited(
      stream, google_firestore_v1beta1_MapValue_fields, &map_value);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }
}

std::map<std::string, FieldValue> DecodeObject(pb_istream_t* stream) {
  google_firestore_v1beta1_MapValue map_value =
      google_firestore_v1beta1_MapValue_init_zero;
  std::map<std::string, FieldValue> result;
  // NB: c-style callbacks can't use *capturing* lambdas, so we'll pass in the
  // object_value via the arg field (and therefore need to do a bunch of
  // casting).
  map_value.fields.funcs.decode = [](pb_istream_t* stream, const pb_field_t*,
                                     void** arg) -> bool {
    auto& result = *static_cast<std::map<std::string, FieldValue>*>(*arg);

    std::pair<std::string, FieldValue> fv = DecodeFieldsEntry(stream);

    // Sanity check: ensure that this key doesn't already exist in the map.
    // TODO(rsgowman): figure out error handling: We can do better than a failed
    // assertion.
    FIREBASE_ASSERT(result.find(fv.first) == result.end());

    // Add this key,fieldvalue to the results map.
    result.emplace(std::move(fv));

    return true;
  };
  map_value.fields.arg = &result;

  bool status = pb_decode_delimited(
      stream, google_firestore_v1beta1_MapValue_fields, &map_value);
  if (!status) {
    // TODO(rsgowman): figure out error handling
    abort();
  }

  return result;
}

}  // namespace

void Serializer::EncodeFieldValue(const FieldValue& field_value,
                                  std::vector<uint8_t>* out_bytes) {
  // TODO(rsgowman): how large should the output buffer be? Do some
  // investigation to see if we can get nanopb to tell us how much space it's
  // going to need. (Hint: use a sizing stream, i.e. PB_OSTREAM_SIZING)
  uint8_t buf[1024];
  pb_ostream_t stream = pb_ostream_from_buffer(buf, sizeof(buf));
  EncodeFieldValueImpl(&stream, field_value);
  out_bytes->insert(out_bytes->end(), buf, buf + stream.bytes_written);
}

FieldValue Serializer::DecodeFieldValue(const uint8_t* bytes, size_t length) {
  pb_istream_t stream = pb_istream_from_buffer(bytes, length);
  return DecodeFieldValueImpl(&stream);
}

}  // namespace remote
}  // namespace firestore
}  // namespace firebase
