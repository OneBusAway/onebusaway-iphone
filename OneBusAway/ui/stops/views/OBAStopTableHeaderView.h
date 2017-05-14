//
//  OBAStopTableHeaderView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/4/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
@import MapKit;

NS_ASSUME_NONNULL_BEGIN

@class OBAArrivalsAndDeparturesForStopV2;

@interface OBAStopTableHeaderView : UIView
@property(nonatomic,assign) BOOL highContrastMode;
@property(nonatomic,strong,readonly) UIButton *menuButton;
@property(nonatomic,strong,readonly) UIButton *filterButton;
- (void)populateTableHeaderFromArrivalsAndDeparturesModel:(OBAArrivalsAndDeparturesForStopV2*)result;
@end

NS_ASSUME_NONNULL_END
