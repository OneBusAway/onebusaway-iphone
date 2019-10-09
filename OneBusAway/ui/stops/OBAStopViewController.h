//
//  OBAStopViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

@class OBAStopViewController;
NS_SWIFT_NAME(EmbeddedStopDelegate)
@protocol OBAEmbeddedStopDelegate<NSObject>
- (void)embeddedStopController:(OBAStopViewController*)stopController pushViewController:(UIViewController*)viewController animated:(BOOL)animated;

- (void)embeddedStopControllerClosePane:(OBAStopViewController*)stopController;

- (CGFloat)embeddedStopControllerBottomLayoutGuideLength;
@end

NS_SWIFT_NAME(StopViewController)
@interface OBAStopViewController : OBAStaticTableViewController
INIT_CODER_UNAVAILABLE;
INIT_NIB_UNAVAILABLE;

@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) PromisedModelService *modelService;
@property(nonatomic,strong) OBALocationManager *locationManager;
@property(nonatomic,copy,readonly) NSString *stopID;
@property(nonatomic,assign) NSUInteger minutesBefore;
@property(nonatomic,assign) NSUInteger minutesAfter;
@property(nonatomic,assign) BOOL presentedFromBookmarks;

@property(nonatomic,assign) BOOL inEmbedMode;
@property(nonatomic,weak) id<OBAEmbeddedStopDelegate> embedDelegate;

- (instancetype)initWithStopID:(NSString*)stopID NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
