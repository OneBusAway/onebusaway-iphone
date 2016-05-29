//
//  NSObject+OBADescription.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/29/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (OBADescription)
- (NSString*)oba_description:(NSArray<NSString*>*)keys;
@end
