/*
 * Copyright 2020 Google LLC
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

#import <Foundation/Foundation.h>

@class FIRAppAttestationToken;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppAttestationTokenHandler)
typedef void (^FIRAppAttestationTokenHandler)(FIRAppAttestationToken *_Nullable token,
                                              NSError *_Nullable error);

NS_SWIFT_NAME(AppAttestationProvider)
@protocol FIRAppAttestationProvider <NSObject>

- (void)getTokenWithCompletion:(FIRAppAttestationTokenHandler)handler
    NS_SWIFT_NAME(getToken(completion:));

@end

NS_ASSUME_NONNULL_END
