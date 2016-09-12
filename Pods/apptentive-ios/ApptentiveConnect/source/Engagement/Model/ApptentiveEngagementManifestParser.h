//
//  ApptentiveEngagementManifestParser.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveInteraction.h"


@interface ApptentiveEngagementManifestParser : NSObject
- (NSDictionary *)targetsAndInteractionsForEngagementManifest:(NSData *)jsonManifest;
- (NSError *)parserError;
@end
