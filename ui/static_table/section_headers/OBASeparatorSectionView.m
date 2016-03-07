//
//  OBASeparatorSectionView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASeparatorSectionView.h"

@implementation OBASeparatorSectionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = OBAGREEN;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 320, [OBATheme defaultPadding])];
}
@end
