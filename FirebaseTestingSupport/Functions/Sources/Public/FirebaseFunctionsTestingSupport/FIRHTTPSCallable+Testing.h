// Copyright 2017 Google
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

// This file is a copy of Functions/Internal/FIRHTTPSCallable+Internal.h except for the modular
// import of FirebaseFunctions.

#import <Foundation/Foundation.h>

@import FirebaseFunctions;

@class FIRFunctions;

NS_ASSUME_NONNULL_BEGIN

@interface FIRHTTPSCallableResult (Testing)

/**
 * Initializes a callable result.
 *
 * @param result The data to wrap.
 */
- (instancetype)initWithData:(id)result;

@end

@interface FIRHTTPSCallable (Testing)

/**
 * Initializes a reference to the given http trigger.
 *
 * @param functionsClient The functions client to use for making network requests.
 * @param name The name of the http trigger.
 */
- (instancetype)initWithFunctions:(FIRFunctions *)functionsClient name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
