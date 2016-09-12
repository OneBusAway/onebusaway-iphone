//
//  ApptentivePersonUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveAPIRequest.h"
#import "ApptentivePersonInfo.h"

extern NSString *const ATPersonLastUpdateValuePreferenceKey;

@protocol ATPersonUpdaterDelegate;


@interface ApptentivePersonUpdater : NSObject <ApptentiveAPIRequestDelegate>
@property (weak, nonatomic) NSObject<ATPersonUpdaterDelegate> *delegate;

+ (BOOL)shouldUpdate;
+ (NSDictionary *)lastSavedVersion;

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)delegate;
- (void)update;
- (void)cancel;
- (float)percentageComplete;
@end

@protocol ATPersonUpdaterDelegate <NSObject>
- (void)personUpdater:(ApptentivePersonUpdater *)personUpdater didFinish:(BOOL)success;
@end
