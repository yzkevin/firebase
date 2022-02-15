// Copyright 2022 LLC Google
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

#import <XCTest/XCTest.h>

@import FirebaseCore;
@import FirebaseFunctions;

@interface ObjCAPICoverage : XCTestCase
@end

@implementation ObjCAPICoverage

- (void)apis {
#pragma mark - Functions

  FIRApp *app = [FIRApp defaultApp];
  FIRFunctions *func = [FIRFunctions functions];
  func = [FIRFunctions functionsForApp:app];
  func = [FIRFunctions functionsForRegion:@"my-region"];
  func = [FIRFunctions functionsForCustomDomain:@"my-domain"];
  func = [FIRFunctions functionsForApp:app region:@"my-region"];
  func = [FIRFunctions functionsForApp:app customDomain:@"my-domain"];

  FIRHTTPSCallable *callable = [func HTTPSCallableWithName:@"name"];

  // Deprecated in Firebase 8, Deleted in Firebase 9
  //[func useFunctionsEmulatorOrigin:@"my-origin"];

  [func useEmulatorWithHost:@"host" port:@"port"];

#pragma mark - HTTPSCallable and HTTPSCallableResult
  [callable
      callWithCompletion:^(FIRHTTPSCallableResult *_Nullable result, NSError *_Nullable error) {
        __unused id data = result.data;
      }];
  [callable callWithObject:nil
                completion:^(FIRHTTPSCallableResult *_Nullable result, NSError *_Nullable error) {
                  [result data];
                }];
  callable.timeoutInterval = 60;
  [callable timeoutInterval];

#pragma mark - FunctionsError
  // Deleted in Firebase 9
  //__unused NSString *str = FIRFunctionsErrorDomain;
  //__unused NSString *str2 = FIRFunctionsErrorDetailsKey;

  // Replaced in Firebase 9
  __unused NSString *str = FIRFunctionsErrorKeys.domain;
  __unused NSString *str2 = FIRFunctionsErrorKeys.errorDetailsKey;
}

- (FIRFunctionsErrorCode)errorCodes:(NSError *)error {
  switch (error.code) {
    case FIRFunctionsErrorCodeOK:
    case FIRFunctionsErrorCodeCancelled:
    case FIRFunctionsErrorCodeUnknown:
    case FIRFunctionsErrorCodeInvalidArgument:
    case FIRFunctionsErrorCodeDeadlineExceeded:
    case FIRFunctionsErrorCodeNotFound:
    case FIRFunctionsErrorCodeAlreadyExists:
    case FIRFunctionsErrorCodePermissionDenied:
    case FIRFunctionsErrorCodeResourceExhausted:
    case FIRFunctionsErrorCodeFailedPrecondition:
    case FIRFunctionsErrorCodeAborted:
    case FIRFunctionsErrorCodeOutOfRange:
    case FIRFunctionsErrorCodeUnimplemented:
    case FIRFunctionsErrorCodeInternal:
    case FIRFunctionsErrorCodeUnavailable:
    case FIRFunctionsErrorCodeDataLoss:
    case FIRFunctionsErrorCodeUnauthenticated:
      return error.code;
  }
}
@end
