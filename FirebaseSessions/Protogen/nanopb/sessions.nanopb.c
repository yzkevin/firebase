/*
 * Copyright 2022 Google LLC
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

/* Automatically generated nanopb constant definitions */
/* Generated by nanopb-0.3.9.9 */

#include "sessions.nanopb.h"

/* @@protoc_insertion_point(includes) */
#if PB_PROTO_HEADER_VERSION != 30
#error Regenerate this file with the current version of nanopb generator.
#endif



const pb_field_t firebase_appquality_sessions_SessionEvent_fields[4] = {
    PB_FIELD(  1, UENUM   , SINGULAR, STATIC  , FIRST, firebase_appquality_sessions_SessionEvent, event_type, event_type, 0),
    PB_FIELD(  2, MESSAGE , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_SessionEvent, session_data, event_type, &firebase_appquality_sessions_SessionInfo_fields),
    PB_FIELD(  3, MESSAGE , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_SessionEvent, application_info, session_data, &firebase_appquality_sessions_ApplicationInfo_fields),
    PB_LAST_FIELD
};

const pb_field_t firebase_appquality_sessions_NetworkConnectionInfo_fields[3] = {
    PB_FIELD(  1, UENUM   , SINGULAR, STATIC  , FIRST, firebase_appquality_sessions_NetworkConnectionInfo, network_type, network_type, 0),
    PB_FIELD(  2, UENUM   , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_NetworkConnectionInfo, mobile_subtype, network_type, 0),
    PB_LAST_FIELD
};

const pb_field_t firebase_appquality_sessions_SessionInfo_fields[6] = {
    PB_FIELD(  1, BYTES   , SINGULAR, POINTER , FIRST, firebase_appquality_sessions_SessionInfo, session_id, session_id, 0),
    PB_FIELD(  2, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_SessionInfo, previous_session_id, session_id, 0),
    PB_FIELD(  3, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_SessionInfo, firebase_installation_id, previous_session_id, 0),
    PB_FIELD(  4, INT64   , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_SessionInfo, event_timestamp_us, firebase_installation_id, 0),
    PB_FIELD(  6, MESSAGE , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_SessionInfo, data_collection_status, event_timestamp_us, &firebase_appquality_sessions_DataCollectionStatus_fields),
    PB_LAST_FIELD
};

const pb_field_t firebase_appquality_sessions_DataCollectionStatus_fields[4] = {
    PB_FIELD(  1, UENUM   , SINGULAR, STATIC  , FIRST, firebase_appquality_sessions_DataCollectionStatus, performance, performance, 0),
    PB_FIELD(  2, UENUM   , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_DataCollectionStatus, crashlytics, performance, 0),
    PB_FIELD(  3, DOUBLE  , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_DataCollectionStatus, session_sampling_rate, crashlytics, 0),
    PB_LAST_FIELD
};

const pb_field_t firebase_appquality_sessions_ApplicationInfo_fields[9] = {
    PB_FIELD(  1, BYTES   , SINGULAR, POINTER , FIRST, firebase_appquality_sessions_ApplicationInfo, app_id, app_id, 0),
    PB_FIELD(  2, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_ApplicationInfo, device_model, app_id, 0),
    PB_FIELD(  3, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_ApplicationInfo, development_platform_name, device_model, 0),
    PB_FIELD(  4, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_ApplicationInfo, development_platform_version, development_platform_name, 0),
    PB_ANONYMOUS_ONEOF_FIELD(platform_info,   5, MESSAGE , ONEOF, STATIC  , OTHER, firebase_appquality_sessions_ApplicationInfo, android_app_info, development_platform_version, &firebase_appquality_sessions_AndroidApplicationInfo_fields),
    PB_ANONYMOUS_ONEOF_FIELD(platform_info,   6, MESSAGE , ONEOF, STATIC  , UNION, firebase_appquality_sessions_ApplicationInfo, apple_app_info, development_platform_version, &firebase_appquality_sessions_AppleApplicationInfo_fields),
    PB_FIELD(  7, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_ApplicationInfo, session_sdk_version, apple_app_info, 0),
    PB_FIELD(  8, UENUM   , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_ApplicationInfo, log_environment, session_sdk_version, 0),
    PB_LAST_FIELD
};

const pb_field_t firebase_appquality_sessions_AndroidApplicationInfo_fields[3] = {
    PB_FIELD(  1, BYTES   , SINGULAR, POINTER , FIRST, firebase_appquality_sessions_AndroidApplicationInfo, package_name, package_name, 0),
    PB_FIELD(  3, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_AndroidApplicationInfo, version_name, package_name, 0),
    PB_LAST_FIELD
};

const pb_field_t firebase_appquality_sessions_AppleApplicationInfo_fields[5] = {
    PB_FIELD(  1, BYTES   , SINGULAR, POINTER , FIRST, firebase_appquality_sessions_AppleApplicationInfo, bundle_short_version, bundle_short_version, 0),
    PB_FIELD(  3, MESSAGE , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_AppleApplicationInfo, network_connection_info, bundle_short_version, &firebase_appquality_sessions_NetworkConnectionInfo_fields),
    PB_FIELD(  4, UENUM   , SINGULAR, STATIC  , OTHER, firebase_appquality_sessions_AppleApplicationInfo, os_name, network_connection_info, 0),
    PB_FIELD(  5, BYTES   , SINGULAR, POINTER , OTHER, firebase_appquality_sessions_AppleApplicationInfo, mcc_mnc, os_name, 0),
    PB_LAST_FIELD
};








/* Check that field information fits in pb_field_t */
#if !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_32BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in 8 or 16 bit
 * field descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(firebase_appquality_sessions_SessionEvent, session_data) < 65536 && pb_membersize(firebase_appquality_sessions_SessionEvent, application_info) < 65536 && pb_membersize(firebase_appquality_sessions_SessionInfo, data_collection_status) < 65536 && pb_membersize(firebase_appquality_sessions_ApplicationInfo, android_app_info) < 65536 && pb_membersize(firebase_appquality_sessions_ApplicationInfo, apple_app_info) < 65536 && pb_membersize(firebase_appquality_sessions_AppleApplicationInfo, network_connection_info) < 65536), YOU_MUST_DEFINE_PB_FIELD_32BIT_FOR_MESSAGES_firebase_appquality_sessions_SessionEvent_firebase_appquality_sessions_NetworkConnectionInfo_firebase_appquality_sessions_SessionInfo_firebase_appquality_sessions_DataCollectionStatus_firebase_appquality_sessions_ApplicationInfo_firebase_appquality_sessions_AndroidApplicationInfo_firebase_appquality_sessions_AppleApplicationInfo)
#endif

#if !defined(PB_FIELD_16BIT) && !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_16BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in the default
 * 8 bit descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(firebase_appquality_sessions_SessionEvent, session_data) < 256 && pb_membersize(firebase_appquality_sessions_SessionEvent, application_info) < 256 && pb_membersize(firebase_appquality_sessions_SessionInfo, data_collection_status) < 256 && pb_membersize(firebase_appquality_sessions_ApplicationInfo, android_app_info) < 256 && pb_membersize(firebase_appquality_sessions_ApplicationInfo, apple_app_info) < 256 && pb_membersize(firebase_appquality_sessions_AppleApplicationInfo, network_connection_info) < 256), YOU_MUST_DEFINE_PB_FIELD_16BIT_FOR_MESSAGES_firebase_appquality_sessions_SessionEvent_firebase_appquality_sessions_NetworkConnectionInfo_firebase_appquality_sessions_SessionInfo_firebase_appquality_sessions_DataCollectionStatus_firebase_appquality_sessions_ApplicationInfo_firebase_appquality_sessions_AndroidApplicationInfo_firebase_appquality_sessions_AppleApplicationInfo)
#endif


/* On some platforms (such as AVR), double is really float.
 * These are not directly supported by nanopb, but see example_avr_double.
 * To get rid of this error, remove any double fields from your .proto.
 */
PB_STATIC_ASSERT(sizeof(double) == 8, DOUBLE_MUST_BE_8_BYTES)

/* @@protoc_insertion_point(eof) */
