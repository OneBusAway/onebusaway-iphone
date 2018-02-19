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

#define kHeaderImageViewBackgroundColor [UIColor colorWithWhite:0.f alpha:0.4f]

@interface OBAStopTableHeaderView ()
@property(nonatomic,strong) UIImageView *headerImageView;
@property(nonatomic,strong) UILabel *stopInformationLabel;
@property(nonatomic,strong) OBAStopV2 *stop;
@property(nonatomic,strong,readwrite) UIButton *menuButton;
@property(nonatomic,strong,readwrite) UIButton *filterButton;
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
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            label;
        });

        _menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_menuButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_menuButton setImage:[UIImage imageNamed:@"ellipsis_button"] forState:UIControlStateNormal];
        _menuButton.tintColor = [UIColor whiteColor];
        _menuButton.accessibilityLabel = NSLocalizedString(@"stop_header_view.menu_button_accessibility_label", @"This is the '...' button in the stop header view.");

        _filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _filterButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_filterButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        _filterButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        [_filterButton setImage:[UIImage imageNamed:@"filter"] forState:UIControlStateNormal];
        _filterButton.tintColor = [UIColor whiteColor];
        _filterButton.accessibilityLabel = NSLocalizedString(@"stop_header_view.filter_button_accessibility_label", @"This is the Filter button in the stop header view.");

        UIStackView *buttonStack = [[UIStackView alloc] initWithArrangedSubviews:@[[UIView new], _filterButton, _menuButton]];
        buttonStack.axis = UILayoutConstraintAxisHorizontal;
        buttonStack.spacing = [OBATheme defaultPadding];
        buttonStack.distribution = UIStackViewDistributionFill;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_stopInformationLabel, buttonStack]];
        stack.axis = UILayoutConstraintAxisVertical;

        [self addSubview:stack];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        [_filterButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(48.f, 40.f)]);
        }];

        [_menuButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(56.f, 40.f)]);
        }];

        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.equalTo(self->_headerImageView);
        }];
    }
    return self;
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
        stopNumber = [NSString stringWithFormat:@"%@ #%@ - %@ %@", NSLocalizedString(@"msg_stop", @"text"), self.stop.code, self.stop.direction, NSLocalizedString(@"msg_bound", @"text")];
    }
    else {
        stopNumber = [NSString stringWithFormat:@"%@ #%@", NSLocalizedString(@"msg_stop", @"text"), self.stop.code];
    }
    [stopMetadata addObject:stopNumber];

    NSString *stopRoutes = [self.stop routeNamesAsString];
    if (stopRoutes) {
        [stopMetadata addObject:[NSString stringWithFormat:NSLocalizedString(@"text_only_routes_colon_param", @""), stopRoutes]];
    }

    self.stopInformationLabel.text = [stopMetadata componentsJoinedByString:@"\r\n"];

    CGSize size = [self.stopInformationLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.frame) - (2 * [OBATheme defaultPadding]), 10000)];

    self.stopInformationLabel.frame = CGRectMake([OBATheme defaultPadding], [OBATheme defaultPadding], size.width, size.height);
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
            options.mapType = [OBAApplication.sharedApplication.userDefaults integerForKey:OBAMapSelectedTypeDefaultsKey];
            [[MKMapSnapshotter alloc] initWithOptions:options];
        });

        [snapshotter start].then(^(MKMapSnapshot *snapshot) {
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
