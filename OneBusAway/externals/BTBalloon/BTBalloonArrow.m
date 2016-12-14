//
//  BTBalloonArrow.m
//
//  Created by Cameron Cooke on 11/03/2014.
//  Copyright (c) 2014 Brightec Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "BTBalloonArrow.h"


@implementation BTBalloonArrow


- (void)setDirection:(BTBalloonArrowDirection)direction
{
    _direction = direction;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(context);
    
    if (self.direction == BTBalloonArrowDirectionUp) {
        CGContextMoveToPoint(context, 0, CGRectGetHeight(self.bounds));
        CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds) / 2, 0);
        CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    } else {
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds));
        CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds), 0);
    }
    
    CGContextClosePath(context);
    
    // fill
    CGContextSetFillColorWithColor(context, self.fillColour.CGColor);
    CGContextFillPath(context);
}


@end
