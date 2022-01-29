
// Copyright 2022 Google LLC
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

#import "FIRSceneHelper.h"
#import <UIKit/UIKit.h>

API_AVAILABLE(ios(13.0))
typedef void (^FIRFindSceneCompletionBlock)(UIWindowScene *scene);

API_AVAILABLE(ios(13.0))
@interface FIRSceneHelper ()
@property(nonatomic, copy) NSMutableArray<FIRFindSceneCompletionBlock> *pendingCompletion;
@end

@implementation FIRSceneHelper

- (instancetype)init {
  self = [super init];
  if (self) {
    _pendingCompletion = [NSMutableArray new];
  }
  return self;
}

- (void)findForegroundedSceneWithCompletionBlock:(void (^)(UIWindowScene *scene))completionBlock
    API_AVAILABLE(ios(13.0)) {
  if (@available(iOS 13.0, *)) {
    UIWindowScene *foregroundedScene = [self findScene];
    if (foregroundedScene != nil) {
      completionBlock(foregroundedScene);
      return;
    }
    [self.pendingCompletion addObject:[completionBlock copy]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onFirstSceneActivated:)
                                                 name:UISceneDidActivateNotification
                                               object:nil];
  } else {
    completionBlock(nil);
  }
}

- (void)onFirstSceneActivated:(NSNotification *)notification API_AVAILABLE(ios(13.0)) {
  UIWindowScene *foregroundedScene;
  if ([notification.object isKindOfClass:[UIWindowScene class]] &&
      ((UIWindowScene *)notification.object).activationState ==
          UISceneActivationStateForegroundActive) {
    foregroundedScene = notification.object;
  } else {
    foregroundedScene = [self findScene];
  }

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UISceneDidActivateNotification
                                                object:nil];
  if (self.pendingCompletion.count > 0) {
    for (FIRFindSceneCompletionBlock pendingBlock in self.pendingCompletion) {
      pendingBlock(foregroundedScene);
    }
    [self.pendingCompletion removeAllObjects];
  }
}

- (UIWindowScene *)findScene API_AVAILABLE(ios(13.0)) {
  for (UIWindowScene *connectedScene in [UIApplication sharedApplication].connectedScenes) {
    if (connectedScene.activationState == UISceneActivationStateForegroundActive) {
      return connectedScene;
    }
  }
  return nil;
}

@end
