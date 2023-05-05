/*
 * Copyright 2023 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "FIRTOTPSecret.h"
#import "FIRMultiFactorSession.h"

NS_ASSUME_NONNULL_BEGIN

/** @class TOTPMultiFactorGenerator
		@brief The data structure used to help initialize an assertion for a second factor entity to the
				Firebase Auth/GCIP server. Depending on the type of second factor, this will help generate
				the assertion.
*/
NS_SWIFT_NAME(TOTPMultiFactorGenerator)
@interface FIRTOTPMultiFactorGenerator : NSObject

/** @fn generateSecretWithMultiFactorSession
		@brief Creates a TOTP secret as part of enrolling a TOTP second factor. Used for generating a QRCode URL or inputting into a TOTP App. This method uses the auth instance corresponding to the user in the multiFactorSession.
		@param session The multiFactorSession instance.
		@param completion Completion block
*/

+ (void)generateSecretWithMultiFactorSession:(FIRMultiFactorSession *)session completion:(void (^)(FIRTOTPSecret *_Nullable secret, NSError *_Nullable error))completion;

/** @fn assertionForEnrollmentWithSecret:
		@brief Initializes the MFA assertion to confirm ownership of the TOTP second factor. This assertion is used to complete enrollment of TOTP as a second factor.
		@param secret The TOTP secret.
		@param oneTimePassword one time password string.
		@param completion completion block
*/
+ (void)assertionForEnrollmentWithSecret:(FIRTOTPSecret *)secret oneTimePassword:(NSString *)oneTimePassword completion:(void (^)(FIRTOTPMultiFactorAssertion *_Nullable, NSError *_Nullable))completion;

/** @fn assertionForSignInWithenrollmentID:
		@brief Initializes the MFA assertion to confirm ownership of the totp second factor. This assertion is used to complete signIn with TOTP as a second factor.
		@param enrollmentID The id that identifies the enrolled TOTP second factor.
		@param oneTimePassword one time password string.
*/
+ (FIRTOTPMultiFactorAssertion *)assertionForSignInWithEnrollmentID: (NSString *)enrollmentID
																										oneTimePassword: (NSString *)oneTimePassword;

@end

NS_ASSUME_NONNULL_END
