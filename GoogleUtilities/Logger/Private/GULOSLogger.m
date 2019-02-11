/*
 * Copyright 2019 Google
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

#import "GULOSLogger.h"

#import <os/log.h>

#import "GULAppEnvironmentUtil.h"
#import "GULLogger+Internal.h"
#import "GULLoggerLevel.h"

NS_ASSUME_NONNULL_BEGIN

// Function which calls the macro so that this can be substituted for testing.
// Since the macro enforces built-in constant-ness of the format string, it is replaced by "s"
// and the va_list should only contain one argument, a full message with format substitutions
// already filled.
static void __gul_os_log_with_type(os_log_t log, os_log_type_t type, char* s, ...) {
  if (@available(iOS 9.0, macOS 10.11, *)) {
    va_list args;
    va_start(args, s);
    os_log_with_type(log, type, "s", args);
    va_end(args);
  } else {
#ifdef DEBUG
    NSCAssert(NO, @"Attempting to use os_log on iOS version prior to 9.");
#endif
  }
}

@interface GULOSLogger ()

@property(nonatomic) NSMutableDictionary<NSString *, os_log_t> *categoryLoggers;
@property(nonatomic) dispatch_queue_t dispatchQueue;
@property(nonatomic, unsafe_unretained) void (*logFunction)(os_log_t, os_log_type_t, char*, ...);

@end

@implementation GULOSLogger

@synthesize forcedDebug = _forcedDebug;
@synthesize logFunction = _logFunction;
@synthesize logLevel = _logLevel;
@synthesize version = _version;

- (instancetype)init {
  self = [super init];
  if (self) {
    _forcedDebug = NO;
    _logLevel = GULLoggerLevelNotice;
    _version = @"";
    _dispatchQueue = dispatch_queue_create("GULLoggerQueue", DISPATCH_QUEUE_SERIAL);
    _logFunction = &__gul_os_log_with_type;
    dispatch_set_target_queue(_dispatchQueue,
                              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
  }
  return self;
}

- (void)initializeLogger {
  dispatch_sync(self.dispatchQueue, ^{
    if (!self.categoryLoggers) {
      self.categoryLoggers = [[NSMutableDictionary<NSString *, os_log_t> alloc] init];
    }
  });
}

- (void)setLogLevel:(GULLoggerLevel)logLevel {
  if (logLevel < GULLoggerLevelMin || logLevel > GULLoggerLevelMax) {
  }

  // We should not raise the logger level if we are running from App Store.
  if (logLevel >= GULLoggerLevelNotice && [GULAppEnvironmentUtil isFromAppStore]) {
    return;
  }
  _logLevel = logLevel;
}

- (GULLoggerLevel)logLevel {
  return _logLevel;
}

- (void)printToSTDERR {
  // NO-OP - os_log always outputs to STDERR and cannot be turned off.
  //         See http://www.openradar.me/36919139
}

- (BOOL)isLoggableLevel:(GULLoggerLevel)logLevel {
  return [GULLogger loggerSystem:self shouldLogMessageOfLevel:logLevel];
}

- (void)logWithLevel:(GULLoggerLevel)level
         withService:(GULLoggerService)service
            isForced:(BOOL)forced
            withCode:(NSString *)messageCode
         withMessage:(NSString *)message, ... {
  [self initializeLogger];
  // Skip logging this if the level isn't to be logged unless it's forced.
  if (![self isLoggableLevel:level] && !forced) {
    return;
  }
  dispatch_async(self.dispatchQueue, ^{
    os_log_t osLog = self.categoryLoggers[service];
    if (!osLog) {
      if (@available(iOS 9.0, macOS 10.11, *)) {
        osLog = os_log_create(kGULLoggerClientFacilityName, service.UTF8String);
        self.categoryLoggers[service] = osLog;
      } else {
#ifdef DEBUG
        NSCAssert(NO, @"Attempting to use os_log on iOS version prior to 9.");
#endif
      }
    }
    (*self.logFunction)(osLog, [[self class] osLogTypeForGULLoggerLevel:level],"%s",
                        [GULLogger messageFromLogger:self
                                         withService:service
                                                code:messageCode
                                             message:message]
                        .UTF8String);
  });
}

+ (os_log_type_t)osLogTypeForGULLoggerLevel:(GULLoggerLevel)level {
  switch (level) {
    case GULLoggerLevelDebug:
      return OS_LOG_TYPE_DEBUG;
    case GULLoggerLevelInfo:
      return OS_LOG_TYPE_INFO;
    case GULLoggerLevelNotice:
    case GULLoggerLevelWarning:
      // Both Notice and Warning map to the os_log default level.
      return OS_LOG_TYPE_DEFAULT;
    case GULLoggerLevelError:
      return OS_LOG_TYPE_ERROR;
    default:
      return OS_LOG_TYPE_DEFAULT;
  }
}

@end

NS_ASSUME_NONNULL_END
