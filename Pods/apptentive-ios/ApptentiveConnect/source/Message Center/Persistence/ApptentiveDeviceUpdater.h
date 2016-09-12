//
//  ApptentiveDeviceUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveAPIRequest.h"

extern NSString *const ATDeviceLastUpdatePreferenceKey;
extern NSString *const ATDeviceLastUpdateValuePreferenceKey;

@protocol ATDeviceUpdaterDelegate;


@interface ApptentiveDeviceUpdater : NSObject <ApptentiveAPIRequestDelegate>
@property (weak, nonatomic) NSObject<ATDeviceUpdaterDelegate> *delegate;
+ (BOOL)shouldUpdate;
+ (NSDictionary *)lastSavedVersion;

- (id)initWithDelegate:(NSObject<ATDeviceUpdaterDelegate> *)delegate;
- (void)update;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ATDeviceUpdaterDelegate <NSObject>
- (void)deviceUpdater:(ApptentiveDeviceUpdater *)deviceUpdater didFinish:(BOOL)success;
@end
