//
//  NSObject+OBADescription.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/29/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (OBADescription)
- (NSString*)oba_description:(NSArray<NSString*>*)keys;
- (NSString*)oba_description:(NSArray<NSString*>*)keys keyPaths:(nullable NSArray<NSString*>*)keyPaths;
@end

NS_ASSUME_NONNULL_END
