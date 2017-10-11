//
//  OBADepartureTimeLabel.m
//  org.onebusaway.iphone
//
//  Created by Chad Royal on 9/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBADepartureTimeLabel.h>
#import <OBAKit/OBAAnimation.h>
#import <OBAKit/OBADepartureCellHelpers.h>
#import <OBAKit/OBADepartureStatus.h>
#import <OBAKit/OBATheme.h>

@interface OBADepartureTimeLabel()
@property(nonatomic,copy) NSString *previousMinutesText;
@property(nonatomic,copy) UIColor *previousMinutesColor;
@property(nonatomic,assign) BOOL firstRenderPass;
@end

@implementation OBADepartureTimeLabel

-(instancetype)init {
    self = [super init];

    if (self) {
        _firstRenderPass = YES;
    }

    return self;
}

#pragma mark - Label Logic

-(void)setText:(NSString *)minutesUntilDeparture forStatus:(OBADepartureStatus)status {
    UIColor *backgroundColor = [OBADepartureCellHelpers colorForStatus:status];

    BOOL textChanged = ![minutesUntilDeparture isEqual:self.previousMinutesText];
    BOOL colorChanged = ![backgroundColor isEqual:self.previousMinutesColor];

    self.previousMinutesText = minutesUntilDeparture;
    self.text = minutesUntilDeparture;

    self.previousMinutesColor = backgroundColor;
    self.textColor = backgroundColor;

    // don't animate the first rendering of the cell.
    if (self.firstRenderPass) {
        self.firstRenderPass = NO;
        return;
    }

    if (textChanged || colorChanged) {
        self.layer.backgroundColor = [OBATheme propertyChangedColor].CGColor;

        [UIView animateWithDuration:OBALongAnimationDuration animations:^{
            self.layer.backgroundColor = self.backgroundColor.CGColor;
        }];
    }
}

@end
