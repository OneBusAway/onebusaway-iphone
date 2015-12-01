//
//  OBAReleaseNotesManager.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/1/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAReleaseNotesManager : NSObject
+ (BOOL)shouldShowReleaseNotes;
+ (void)showReleaseNotes:(UIWindow*)window;
@end

NS_ASSUME_NONNULL_END