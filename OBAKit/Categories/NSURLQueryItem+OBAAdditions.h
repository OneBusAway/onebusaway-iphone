//
//  NSURLQueryItem+OBAAdditions.h
//  OBAKit
//
//  Created by Aaron Brethorst on 10/30/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSURLQueryItem (OBAAdditions)
+ (NSDictionary*)oba_dictionaryFromQueryItems:(nullable NSArray<NSURLQueryItem*>*)queryItems;
@end

NS_ASSUME_NONNULL_END
