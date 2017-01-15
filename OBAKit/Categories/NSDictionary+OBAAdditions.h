//
//  NSDictionary+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/11/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;

@interface NSDictionary (OBAAdditions)
- (NSData*)oba_toHTTPBodyData;
@end
