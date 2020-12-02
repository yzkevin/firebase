// Copyright 2019 Google
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

#import "Crashlytics/Crashlytics/Helpers/FIRCLSFCRAnalytics.h"

#import "Crashlytics/Crashlytics/Helpers/FIRCLSInternalLogging.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSSettings.h"

#import "Interop/Analytics/Public/FIRAnalyticsInterop.h"

// Origin for events and user properties generated by Crashlytics.
static NSString *const kFIREventOriginCrash = @"clx";

// App exception event name.
static NSString *const kFIREventAppException = @"_ae";

// Timestamp key for the event payload.
static NSString *const kFIRParameterTimestamp = @"timestamp";

// Fatal key for the event payload.
static NSString *const kFIRParameterFatal = @"fatal";

FOUNDATION_STATIC_INLINE NSNumber *timeIntervalInMillis(NSTimeInterval timeInterval) {
  return @(llrint(timeInterval * 1000.0));
}

@implementation FIRCLSFCRAnalytics

+ (void)logCrashWithTimeStamp:(NSTimeInterval)crashTimeStamp
                  toAnalytics:(id<FIRAnalyticsInterop>)analytics {
  if (analytics == nil) {
    return;
  }

  FIRCLSDeveloperLog(@"Crashlytics:Crash:Reports:Event",
                     "Sending app_exception event to Firebase Analytics for crash-free statistics");
  NSDictionary *params = [self buildLogParamsFromCrash:crashTimeStamp];
  [analytics logEventWithOrigin:kFIREventOriginCrash name:kFIREventAppException parameters:params];
}

+ (void)registerEventListener:(id<FIRAnalyticsInteropListener>)eventListener
                  toAnalytics:(id<FIRAnalyticsInterop>)analytics {
  if (analytics == nil) {
    FIRCLSDeveloperLog(@"Crashlytics:Crash:Reports:Event",
                       "Firebase Analytics SDK not detected so crash-free statistics and breadcrumbs will not be reported");
    return;
  }

  [analytics registerAnalyticsListener:eventListener withOrigin:kFIREventOriginCrash];

  FIRCLSDeveloperLog(@"Crashlytics:Crash:Reports:Event",
                     "Registered Firebase Analytics event listener to receive breadcrumb logs");
}

/**
 * Builds a dictionary of params to be sent to Analytics using the crash object.
 *
 * @param crashTimeStamp The time stamp of the crash to be logged.
 *
 * @return An NSDictionary containing the time the crash occured and the fatal
 *   flag to be fed into Firebase Analytics.
 */
+ (NSDictionary *)buildLogParamsFromCrash:(NSTimeInterval)crashTimeStamp {
  return @{
    kFIRParameterTimestamp : timeIntervalInMillis(crashTimeStamp),
    kFIRParameterFatal : @(INT64_C(1))
  };
}

@end
