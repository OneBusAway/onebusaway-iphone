//
//  UIView+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 3/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/UIView+OBAAdditions.h>
#import <OBAKit/OBAKit-Swift.h>
@import Masonry;

@implementation UIView (OBAAdditions)

+ (instancetype)oba_autolayoutNew {
    id view = [[self alloc] initWithFrame:CGRectZero];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];

    return view;
}

- (OBACardWrapper*)oba_embedInCardWrapper {
    OBACardWrapper *wrapper = [[OBACardWrapper alloc] initWithFrame:CGRectZero];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper.contentView addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(wrapper.contentView);
    }];

    return wrapper;
}

- (UIView*)oba_embedInWrapperView {
    return [self oba_embedInWrapperViewWithConstraints:YES];
}

- (UIView*)oba_embedInWrapperViewWithConstraints:(BOOL)constrained {
    UIView *wrapper = [[UIView alloc] initWithFrame:CGRectZero];
    [wrapper addSubview:self];
    if (constrained) {
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(wrapper);
        }];
    }
    return wrapper;
}

- (void)printAutoLayoutTrace {
#ifdef DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"_autolayoutTrace");
    NSLog(@"%@", [self performSelector:selector]);
#pragma clang diagnostic pop
#endif
}

- (void)exerciseAmbiguityInLayoutRepeatedly:(BOOL)recursive {
#ifdef DEBUG
    if (self.hasAmbiguousLayout) {
        [NSTimer scheduledTimerWithTimeInterval:.5
                                         target:self
                                       selector:@selector(exerciseAmbiguityInLayout)
                                       userInfo:nil
                                        repeats:YES];
    }
    if (recursive) {
        for (UIView *subview in self.subviews) {
            [subview exerciseAmbiguityInLayoutRepeatedly:YES];
        }
    }
#endif
}

@end
