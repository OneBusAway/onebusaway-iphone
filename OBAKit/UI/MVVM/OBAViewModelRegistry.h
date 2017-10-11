//
//  OBAViewModelRegistry.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

@interface OBAViewModelRegistry : NSObject
+ (void)registerClass:(Class)klass;
+ (NSArray*)registeredClasses;
@end
