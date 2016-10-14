//
//  UIViewController+OBAAnalytics.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/26/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "UIViewController+OBAAnalytics.h"
#import <objc/runtime.h>
#import "OBAAnalytics.h"

@implementation UIViewController (OBAAnalytics)

// Adapted from http://nshipster.com/method-swizzling/
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(oba_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method Swizzling

- (void)oba_viewWillAppear:(BOOL)animated {
    [self oba_viewWillAppear:animated];
    
    if ([NSStringFromClass(self.class) hasPrefix:@"OBA"]) {
        // Not a system class, and therefore something worth tracking.
        [OBAAnalytics reportViewController:self];
    }
}
@end
