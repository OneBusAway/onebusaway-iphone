//
//  ApptentiveWebClient+EngagementAdditions.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveWebClient.h"


@interface ApptentiveWebClient (EngagementAdditions)
- (ApptentiveAPIRequest *)requestForGettingEngagementManifest;
@end
