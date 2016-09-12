//
//  ApptentiveInteractionUsageData.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveInteraction.h"


@interface ApptentiveInteractionUsageData : NSObject

@property (strong, nonatomic) NSNumber *timeSinceInstallTotal;
@property (strong, nonatomic) NSNumber *timeSinceInstallVersion;
@property (strong, nonatomic) NSNumber *timeSinceInstallBuild;
@property (strong, nonatomic) NSDate *timeAtInstallTotal;
@property (strong, nonatomic) NSDate *timeAtInstallVersion;
@property (copy, nonatomic) NSString *applicationVersion;
@property (copy, nonatomic) NSString *applicationBuild;
@property (copy, nonatomic) NSString *sdkVersion;
@property (copy, nonatomic) NSString *sdkDistribution;
@property (copy, nonatomic) NSString *sdkDistributionVersion;
@property (strong, nonatomic) NSNumber *currentTime;
@property (strong, nonatomic) NSNumber *isUpdateVersion;
@property (strong, nonatomic) NSNumber *isUpdateBuild;
@property (copy, nonatomic) NSDictionary *codePointInvokesTotal;
@property (copy, nonatomic) NSDictionary *codePointInvokesVersion;
@property (copy, nonatomic) NSDictionary *codePointInvokesBuild;
@property (copy, nonatomic) NSDictionary *codePointInvokesTimeAgo;
@property (copy, nonatomic) NSDictionary *interactionInvokesTotal;
@property (copy, nonatomic) NSDictionary *interactionInvokesVersion;
@property (copy, nonatomic) NSDictionary *interactionInvokesBuild;
@property (copy, nonatomic) NSDictionary *interactionInvokesTimeAgo;

+ (ApptentiveInteractionUsageData *)usageData;

- (NSDictionary *)predicateEvaluationDictionary;

+ (void)keyPathWasSeen:(NSString *)keyPath;

@end
