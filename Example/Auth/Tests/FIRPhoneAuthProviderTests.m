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

#import <XCTest/XCTest.h>

#import "Phone/FIRPhoneAuthProvider.h"
#import "Phone/FIRPhoneAuthCredential_Internal.h"
#import "Phone/NSString+FIRAuth.h"
#import "FIRAuthAPNSToken.h"
#import "FIRAuthAPNSTokenManager.h"
#import "FIRAuth_Internal.h"
#import "FIRAuthCredential_Internal.h"
#import "FIRAuthErrorUtils.h"
#import "FIRAuthGlobalWorkQueue.h"
#import "FIRAuthBackend.h"
#import "FIRSendVerificationCodeRequest.h"
#import "FIRSendVerificationCodeResponse.h"
#import "FIRVerifyClientRequest.h"
#import "FIRVerifyClientResponse.h"
#import "FIRApp+FIRAuthUnitTests.h"
#import "OCMStubRecorder+FIRAuthUnitTests.h"
#import <OCMock/OCMock.h>

/** @var kTestPhoneNumber
    @brief A testing phone number.
 */
static NSString *const kTestPhoneNumber = @"55555555";

/** @var kTestInvalidPhoneNumber
    @brief An invalid testing phone number.
 */
static NSString *const kTestInvalidPhoneNumber = @"555+!*55555";

/** @var kTestVerificationID
    @brief A testing verfication ID.
 */
static NSString *const kTestVerificationID = @"verificationID";

/** @var kTestReceipt
    @brief A fake receipt for testing.
 */
static NSString *const kTestReceipt = @"receipt";

/** @var kTestVerificationCode
    @brief A testing verfication code.
 */
static NSString *const kTestVerificationCode = @"verificationCode";

/** @var kAPIKey
    @brief The fake API key.
 */
static NSString *const kAPIKey = @"FAKE_API_KEY";

/** @var kExpectationTimeout
    @brief The maximum time waiting for expectations to fulfill.
 */
static const NSTimeInterval kExpectationTimeout = 1;

/** @class FIRPhoneAuthProviderTests
    @brief Tests for @c FIRPhoneAuthProvider
 */
@interface FIRPhoneAuthProviderTests : XCTestCase
@end

@implementation FIRPhoneAuthProviderTests {
  /** @var _mockBackend
      @brief The mock @c FIRAuthBackendImplementation .
   */
  id _mockBackend;
}

- (void)setUp {
  [super setUp];
  _mockBackend = OCMProtocolMock(@protocol(FIRAuthBackendImplementation));
  [FIRAuthBackend setBackendImplementation:_mockBackend];
  [FIRApp resetAppForAuthUnitTests];
}

- (void)tearDown {
  [FIRAuthBackend setDefaultBackendImplementationWithRPCIssuer:nil];
  [super tearDown];
}

/** @fn testCredentialWithVerificationID
    @brief Tests the @c credentialWithToken method to make sure that it returns a valid
        FIRAuthCredential instance.
 */
- (void)testCredentialWithVerificationID {
  FIRPhoneAuthCredential *credential =
      [[FIRPhoneAuthProvider provider] credentialWithVerificationID:kTestVerificationID
                                                   verificationCode:kTestVerificationCode];
  XCTAssertEqualObjects(credential.verificationID, kTestVerificationID);
  XCTAssertEqualObjects(credential.verificationCode, kTestVerificationCode);
  XCTAssertNil(credential.temporaryProof);
  XCTAssertNil(credential.phoneNumber);
}

/** @fn testVerifyEmptyPhoneNumber
    @brief Tests a failed invocation @c verifyPhoneNumber:completion: because an empty phone
        number was provided.
 */
- (void)testVerifyEmptyPhoneNumber {
  XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
  [[FIRPhoneAuthProvider provider] verifyPhoneNumber:@""
                                          completion:^(NSString *_Nullable verificationID,
                                                       NSError *_Nullable error) {
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, FIRAuthErrorCodeMissingPhoneNumber);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:kExpectationTimeout handler:nil];
}

#ifdef FLAKY

/** @fn testVerifyInvalidPhoneNumber
    @brief Tests a failed invocation @c verifyPhoneNumber:completion: because an invalid phone
        number was provided.
 */
- (void)testVerifyInvalidPhoneNumber {
  XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
  OCMExpect([_mockBackend sendVerificationCode:[OCMArg any] callback:[OCMArg any]])
      .andCallBlock2(^(FIRSendVerificationCodeRequest *request,
                       FIRSendVerificationCodeResponseCallback callback) {
    XCTAssertNotNil(request);
    dispatch_async(FIRAuthGlobalWorkQueue(), ^() {
      callback(nil, [FIRAuthErrorUtils invalidPhoneNumberErrorWithMessage:nil]);
    });
  });

  // Expect verify Client request to the backend.
  OCMExpect([_mockBackend verifyClient:[OCMArg any] callback:[OCMArg any]])
      .andCallBlock2(^(FIRVerifyClientRequest *request,
                       FIRVerifyClientResponseCallback callback) {
    XCTAssertNotNil(request);
    dispatch_async(FIRAuthGlobalWorkQueue(), ^() {
      id mockVerifyClientResponse = OCMClassMock([FIRVerifyClientResponse class]);
      OCMStub([mockVerifyClientResponse receipt]).andReturn(kTestReceipt);
      OCMStub([mockVerifyClientResponse suggestedTimeOutDate]).andReturn([NSDate date]);
      callback(mockVerifyClientResponse, nil);
    });
  });

  // Manually set APNS token on FIRAuth intance.
  FIRAuthAPNSToken *token =
      [[FIRAuthAPNSToken alloc] initWithData:[NSData data] type:FIRAuthAPNSTokenTypeProd];
  [FIRAuth auth].tokenManager.token = token;

  [[FIRPhoneAuthProvider provider] verifyPhoneNumber:kTestPhoneNumber
                                          completion:^(NSString *_Nullable verificationID,
                                                       NSError *_Nullable error) {
    XCTAssertNil(verificationID);
    XCTAssertEqual(error.code, FIRAuthErrorCodeInvalidPhoneNumber);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:kExpectationTimeout handler:nil];
  OCMVerifyAll(_mockBackend);
}

/** @fn testVerifyPhoneNumber
    @brief Tests a successful invocation of @c verifyPhoneNumber:completion:.
 */
- (void)testVerifyPhoneNumber {
  XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
  OCMExpect([_mockBackend sendVerificationCode:[OCMArg any] callback:[OCMArg any]])
      .andCallBlock2(^(FIRSendVerificationCodeRequest *request,
                       FIRSendVerificationCodeResponseCallback callback) {
    XCTAssertNotNil(request);
    dispatch_async(FIRAuthGlobalWorkQueue(), ^() {
      id mockSendVerificationCodeResponse = OCMClassMock([FIRSendVerificationCodeResponse class]);
      OCMStub([mockSendVerificationCodeResponse verificationID]).andReturn(kTestVerificationID);
      callback(mockSendVerificationCodeResponse, nil);
    });
  });

  // Expect verify Client request to the backend.
  OCMExpect([_mockBackend verifyClient:[OCMArg any] callback:[OCMArg any]])
      .andCallBlock2(^(FIRVerifyClientRequest *request,
                       FIRVerifyClientResponseCallback callback) {
    XCTAssertNotNil(request);
    dispatch_async(FIRAuthGlobalWorkQueue(), ^() {
      id mockVerifyClientResponse = OCMClassMock([FIRVerifyClientResponse class]);
      OCMStub([mockVerifyClientResponse receipt]).andReturn(kTestReceipt);
      OCMStub([mockVerifyClientResponse suggestedTimeOutDate]).andReturn([NSDate date]);
      callback(mockVerifyClientResponse, nil);
    });
  });

  // Manually set APNS token on FIRAuth intance.
  FIRAuthAPNSToken *token =
      [[FIRAuthAPNSToken alloc] initWithData:[NSData data] type:FIRAuthAPNSTokenTypeProd];
  [FIRAuth auth].tokenManager.token = token;

  [[FIRPhoneAuthProvider provider] verifyPhoneNumber:kTestPhoneNumber
                                          completion:^(NSString *_Nullable verificationID,
                                                       NSError *_Nullable error) {
    XCTAssertNil(error);
    XCTAssertEqualObjects(verificationID, kTestVerificationID);
    XCTAssertEqualObjects(verificationID.fir_authPhoneNumber, kTestPhoneNumber);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:kExpectationTimeout handler:nil];
  OCMVerifyAll(_mockBackend);
}

/** @fn testVerifyPhoneNumberCustomAuth
    @brief Tests a successful invocation @c verifyPhoneNumber:completion: with a custom auth object.
 */
- (void)testVerifyPhoneNumberCustomAuth {
  XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
  OCMExpect([_mockBackend sendVerificationCode:[OCMArg any] callback:[OCMArg any]])
      .andCallBlock2(^(FIRSendVerificationCodeRequest *request,
                       FIRSendVerificationCodeResponseCallback callback) {
    XCTAssertEqualObjects(request.APIKey, kAPIKey);
    dispatch_async(FIRAuthGlobalWorkQueue(), ^() {
      id mockSendVerificationCodeResponse = OCMClassMock([FIRSendVerificationCodeResponse class]);
      OCMStub([mockSendVerificationCodeResponse verificationID]).andReturn(kTestVerificationID);
      callback(mockSendVerificationCodeResponse, nil);
    });
  });

  // Expect verify Client request to the backend.
  OCMExpect([_mockBackend verifyClient:[OCMArg any] callback:[OCMArg any]])
      .andCallBlock2(^(FIRVerifyClientRequest *request,
                       FIRVerifyClientResponseCallback callback) {
    XCTAssertNotNil(request);
    dispatch_async(FIRAuthGlobalWorkQueue(), ^() {
      id mockVerifyClientResponse = OCMClassMock([FIRVerifyClientResponse class]);
      OCMStub([mockVerifyClientResponse receipt]).andReturn(kTestReceipt);
      OCMStub([mockVerifyClientResponse suggestedTimeOutDate]).andReturn([NSDate date]);
      callback(mockVerifyClientResponse, nil);
    });
  });

  FIRAuthAPNSToken *token =
      [[FIRAuthAPNSToken alloc] initWithData:[NSData data] type:FIRAuthAPNSTokenTypeProd];
  FIRAuthAPNSTokenManager *tokenManager =
      [[FIRAuthAPNSTokenManager alloc] initWithApplication:OCMClassMock([UIApplication class])];
  tokenManager.token = token;

  // Create partial mock object to act as custom auth object.
  id customAuth = OCMPartialMock([FIRAuth auth]);
  OCMStub([customAuth APIKey]).andReturn(kAPIKey);
  OCMStub([customAuth tokenManager]).andReturn(tokenManager);

  FIRPhoneAuthProvider *provider = [FIRPhoneAuthProvider providerWithAuth:customAuth];
  [provider verifyPhoneNumber:kTestPhoneNumber
                   completion:^(NSString *_Nullable verificationID,
                                NSError *_Nullable error) {
    XCTAssertNil(error);
    XCTAssertEqualObjects(verificationID, kTestVerificationID);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:kExpectationTimeout handler:nil];
  OCMVerifyAll(_mockBackend);
}

#endif

@end
