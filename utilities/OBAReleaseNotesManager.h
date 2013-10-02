//
//  OBAReleaseNotesManager.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/1/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAReleaseNotesManager : NSObject
+ (BOOL)shouldShowReleaseNotes;
+ (void)showReleaseNotes:(UIWindow*)window;
@end
