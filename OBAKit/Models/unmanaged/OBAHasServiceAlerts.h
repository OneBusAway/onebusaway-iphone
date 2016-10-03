//
//  OBAHasServiceAlerts.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

@class OBASituationV2;

@protocol OBAHasServiceAlerts <NSObject>
- (NSArray<OBASituationV2*>*)situations;
- (void)addSituationId:(NSString*)situationId;
@end
