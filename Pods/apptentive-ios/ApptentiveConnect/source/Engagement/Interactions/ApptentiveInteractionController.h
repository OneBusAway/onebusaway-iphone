//
//  ApptentiveInteractionController.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ApptentiveInteraction;


@interface ApptentiveInteractionController : NSObject

+ (void)registerInteractionControllerClass:(Class) class forType:(NSString *)type;
+ (instancetype)interactionControllerWithInteraction:(ApptentiveInteraction *)interaction;

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction;

@property (readonly, nonatomic) ApptentiveInteraction *interaction;

- (void)presentInteractionFromViewController:(UIViewController *)viewController;

@end
