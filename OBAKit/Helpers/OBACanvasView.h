//
//  OBACanvasView.h
//  org.onebusaway.iphone
//
//  Created by Chad Royal on 10/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBACanvasView : UIView

// This is a lightweight view derived from UIView to offer only an opportunity
// to have a custom drawRect implementation with a reusable class rather than
// having N tiny classes with different drawing code. Because there's no other
// functionality needed, I chose a simple block model to do the drawing.
- (instancetype)initWithFrame:(CGRect)frame drawRectBlock:(void(^)(CGRect))drawBlock;

@end
