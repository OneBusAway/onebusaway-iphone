//
//  OBAAutoLabel.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/27/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAAutoLabel.h>

@implementation OBAAutoLabel

- (void)setBounds:(CGRect)bounds {
    if (bounds.size.width != self.bounds.size.width) {
        [self setNeedsUpdateConstraints];
    }
    [super setBounds:bounds];
}

- (void)updateConstraints {
    if (self.preferredMaxLayoutWidth != self.bounds.size.width) {
        self.preferredMaxLayoutWidth = self.bounds.size.width;
    }
    [super updateConstraints];
}

@end
