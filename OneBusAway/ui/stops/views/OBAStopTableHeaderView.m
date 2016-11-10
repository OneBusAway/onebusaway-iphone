//
//  OBAStopTableHeaderView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/4/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStopTableHeaderView.h"
@import OBAKit;
@import Masonry;
@import PromiseKit;
@import PMKMapKit;
@import PMKCoreLocation;
#import "OBAAnimation.h"

#define kHeaderImageViewBackgroundColor [UIColor colorWithWhite:0.f alpha:0.4f]

@interface OBAStopTableHeaderView ()
@property(nonatomic,strong) UIImageView *headerImageView;
@property(nonatomic,strong) UILabel *stopInformationLabel;
@property(nonatomic,strong) UILabel *directionsLabel;
@property(nonatomic,strong) OBAStopV2 *stop;
@end

@implementation OBAStopTableHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [OBATheme backgroundColor];
        self.clipsToBounds = YES;

        _headerImageView = ({
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
            imageView.backgroundColor = kHeaderImageViewBackgroundColor;
            imageView.contentMode = UIViewContentModeCenter;
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 1.f;
            imageView;
        });
        [self addSubview:_headerImageView];

        _stopInformationLabel = ({
            UILabel *label = [OBAUIBuilder label];
            label.numberOfLines = 0;
            [self.class applyHeaderStylingToLabel:label];
            label;
        });

        _directionsLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            [self.class applyHeaderStylingToLabel:label];
            label.numberOfLines = 0;
            [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

            label.userInteractionEnabled = YES;
            label;
        });

        UIView *wrapper = [[UIView alloc] initWithFrame:self.bounds];
        wrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:wrapper];

        [wrapper addSubview:_stopInformationLabel];
        [wrapper addSubview:_directionsLabel];
    }
    return self;
}

#pragma mark - Auto Layout

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {

    UIView *superview = self.stopInformationLabel.superview;

    [self.directionsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.and.right.equalTo(superview).insets(UIEdgeInsetsMake(0.f, [OBATheme defaultPadding], [OBATheme defaultPadding], [OBATheme defaultPadding]));
    }];

    [self.stopInformationLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.and.right.equalTo(superview).insets(UIEdgeInsetsMake([OBATheme defaultPadding], [OBATheme defaultPadding], 0, [OBATheme defaultPadding]));
        make.bottom.equalTo(self.directionsLabel.mas_top).offset(-[OBATheme defaultPadding]);
    }];

    // According to Apple, -super should be called at end of method
    [super updateConstraints];
}

#pragma mark - Public

- (void)populateTableHeaderFromArrivalsAndDeparturesModel:(OBAArrivalsAndDeparturesForStopV2*)result {

    self.stop = result.stop;

    [self populateHeaderBackground];

    NSMutableArray *stopMetadata = [[NSMutableArray alloc] init];

    if (self.stop.name) {
        [stopMetadata addObject:self.stop.name];
    }

    NSString *stopNumber = nil;

    if (self.stop.direction) {
        stopNumber = [NSString stringWithFormat:@"%@ #%@ - %@ %@", NSLocalizedString(@"Stop", @"text"), self.stop.code, self.stop.direction, NSLocalizedString(@"bound", @"text")];
    }
    else {
        stopNumber = [NSString stringWithFormat:@"%@ #%@", NSLocalizedString(@"Stop", @"text"), self.stop.code];
    }
    [stopMetadata addObject:stopNumber];

    NSString *stopRoutes = [self.stop routeNamesAsString];
    if (stopRoutes) {
        [stopMetadata addObject:[NSString stringWithFormat:NSLocalizedString(@"Routes: %@", @""), stopRoutes]];
    }

    self.stopInformationLabel.text = [stopMetadata componentsJoinedByString:@"\r\n"];
}

#pragma mark - Walking Distance

- (void)setWalkingETA:(MKETAResponse *)walkingETA {
    if (_walkingETA == walkingETA) {
        return;
    }

    _walkingETA = walkingETA;

    if (!_walkingETA) {
        [self.directionsLabel removeFromSuperview];
        return;
    }

    NSString *walkText = [NSString stringWithFormat:NSLocalizedString(@"Walk to stop: %@ — %.0f min, arriving at %@.",), [OBAMapHelpers stringFromDistance:_walkingETA.distance],
                                 [[NSDate dateWithTimeIntervalSinceNow:_walkingETA.expectedTravelTime] minutesUntil],
                                 [OBADateHelpers formatShortTimeNoDate:_walkingETA.expectedArrivalDate]];

    UIImage *walkImage = [[UIImage imageNamed:@"walkTransport"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.directionsLabel.attributedText = [self attributedStringWithValue:walkText image:walkImage];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showWalkingDirections:)];
    [self.directionsLabel addGestureRecognizer:tapRecognizer];

    [OBAAnimation performAnimations:^{
        [self setNeedsUpdateConstraints];
    }];
}

- (NSAttributedString *)attributedStringWithValue:(NSString *)string image:(UIImage *)image {
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.bounds = CGRectMake(0, 0, 12, 16);
    attachment.image = image;

    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [mutableAttributedString appendAttributedString:attachmentString];
    [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:0] range:NSMakeRange(0, mutableAttributedString.length)]; // Put font size 0 to prevent offset
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, mutableAttributedString.length)];
    [mutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];

    NSAttributedString *ratingText = [[NSAttributedString alloc] initWithString:string];
    [mutableAttributedString appendAttributedString:ratingText];
    return mutableAttributedString;
}

- (void)showWalkingDirections:(UITapGestureRecognizer*)tap {
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.stop.coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.stop.name;

    [mapItem openInMapsWithLaunchOptions:@{
                                           MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
                                           MKLaunchOptionsMapTypeKey: @(MKMapTypeStandard),
                                           MKLaunchOptionsShowsTrafficKey: @NO
                                           }];
}

#pragma mark - Private Helpers

+ (void)applyHeaderStylingToLabel:(UILabel*)label {
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    label.shadowOffset = CGSizeMake(0, 1);
    label.font = [OBATheme bodyFont];
}

- (void)populateHeaderBackground {
    if (self.highContrastMode) {
        self.headerImageView.backgroundColor = [OBATheme OBAGreen];
    }
    else {
        MKMapSnapshotter *snapshotter = ({
            MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];

            CGFloat squareDimension = MAX(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
            CGSize squareSize = CGSizeMake(squareDimension, squareDimension);

            options.region = [OBAMapHelpers coordinateRegionWithCenterCoordinate:self.stop.coordinate zoomLevel:15 viewSize:squareSize];
            options.size = squareSize;
            options.scale = [[UIScreen mainScreen] scale];
            [[MKMapSnapshotter alloc] initWithOptions:options];
        });

        [snapshotter start].thenInBackground(^(MKMapSnapshot *snapshot) {
            UIImage *annotatedImage = [OBAImageHelpers draw:[OBAStopIconFactory getIconForStop:self.stop]
                                                       onto:snapshot.image
                                                    atPoint:[snapshot pointForCoordinate:self.stop.coordinate]];
            return [OBAImageHelpers colorizeImage:annotatedImage withColor:kHeaderImageViewBackgroundColor];
        }).then(^(UIImage *colorizedImage) {
            self.headerImageView.image = colorizedImage;
        });
    }
}

@end
