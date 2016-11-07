//
//  OBAParallaxTableHeaderView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/4/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

@class OBAArrivalsAndDeparturesForStopV2;

@interface OBAParallaxTableHeaderView : UIView
@property(nonatomic,assign) BOOL highContrastMode;
- (void)populateTableHeaderFromArrivalsAndDeparturesModel:(OBAArrivalsAndDeparturesForStopV2*)result;
@end
