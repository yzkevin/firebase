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

#import "FIRAppAttestStoredToken.h"

static NSString *const kTokenKey = @"token";
static NSString *const kExpirationDateKey = @"expirationDate";
static NSString *const kStorageVersionKey = @"storageVersion";

static const NSInteger kStorageVersion = 1;

NS_ASSUME_NONNULL_BEGIN

@implementation FIRAppAttestStoredToken

- (NSInteger)storageVersion {
  return kStorageVersion;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.token forKey:kTokenKey];
  [coder encodeObject:self.expirationDate forKey:kExpirationDateKey];
  [coder encodeInteger:self.storageVersion forKey:kStorageVersionKey];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    NSInteger storageVersion = [coder decodeIntegerForKey:kStorageVersionKey];
    if (storageVersion > kStorageVersion) {
      // TODO: Log a message.
    }

    _token = [coder decodeObjectOfClass:[NSString class] forKey:kTokenKey];
    _expirationDate = [coder decodeObjectOfClass:[NSDate class] forKey:kExpirationDateKey];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
