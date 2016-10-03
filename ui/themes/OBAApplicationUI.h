//
//  OBAApplicationUI.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBANavigationTarget.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OBAApplicationUI<NSObject>
@property(nonatomic,strong,readonly) UIViewController *rootViewController;

- (void)performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler;
- (void)applicationDidBecomeActive;
- (void)navigateToTargetInternal:(OBANavigationTarget*)navigationTarget;
- (void)updateSelectedTabIndex;
@end

NS_ASSUME_NONNULL_END
