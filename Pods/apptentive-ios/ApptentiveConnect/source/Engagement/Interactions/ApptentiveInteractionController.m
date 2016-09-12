//
//  ApptentiveInteractionController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"
#import "ApptentiveInteraction.h"

static NSDictionary *interactionControllerClassRegistry;


@implementation ApptentiveInteractionController

+ (void)registerInteractionControllerClass:(Class) class forType:(NSString *)type {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        interactionControllerClassRegistry = @{};
	});

	@synchronized([ApptentiveInteractionController class]) {
		NSMutableDictionary *registry = [interactionControllerClassRegistry mutableCopy];
		registry[type] = class;
		interactionControllerClassRegistry = [NSDictionary dictionaryWithDictionary:registry];
	}
}

	+ (Class)interactionControllerClassWithType : (NSString *)type {
	Class result;
	@synchronized([ApptentiveInteractionController class]) {
		result = interactionControllerClassRegistry[type];
	}
	return result;
}

+ (instancetype)interactionControllerWithInteraction:(ApptentiveInteraction *)interaction {
	Class controllerClass = [self interactionControllerClassWithType:interaction.type] ?: [self class];

	return [[controllerClass alloc] initWithInteraction:interaction];
}

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction {
	self = [super init];

	if (self) {
		_interaction = interaction;
	}

	return self;
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	ApptentiveLogInfo(@"Unable to present interaction with unknown type “%@”", self.interaction.type);
}

@end
