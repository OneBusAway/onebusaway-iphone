//
//  OBAApplicationConfiguration.h
//  OBAKit
//
//  Created by Aaron Brethorst on 5/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
@import CocoaLumberjack;

NS_ASSUME_NONNULL_BEGIN

@interface OBAApplicationConfiguration : NSObject
@property(nonatomic,copy,nullable) NSArray<DDAbstractLogger*> *loggers;
@end

NS_ASSUME_NONNULL_END
