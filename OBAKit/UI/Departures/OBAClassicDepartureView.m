//
//  OBAClassicDepartureView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAClassicDepartureView.h>
@import Masonry;
#import <OBAKit/OBAAnimation.h>
#import <OBAKit/OBADepartureTimeLabel.h>
#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBADepartureCellHelpers.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/UIView+OBAAdditions.h>
#import <OBAKit/OBAKit-Swift.h>

#define kUseDebugColors NO

@interface OBAClassicDepartureView ()

@property(nonatomic,strong) UIStackView *leftLabelStack;
@property(nonatomic,strong) UILabel *topLineLabel;
@property(nonatomic,strong) UILabel *middleLineLabel;
@property(nonatomic,strong) UILabel *bottomLineLabel;

@property(nonatomic,strong) UIStackView *departureLabelStack;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *firstDepartureLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *secondDepartureLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *thirdDepartureLabel;
@property(nonatomic,strong) UIView *departureLabelSpacer;
@property(nonatomic,strong,readwrite) OBAOccupancyStatusView *occupancyStatusView;
@property(nonatomic,strong) UIView *occupancyStatusWrapper;

@property(nonatomic,strong,readwrite) UIButton *contextMenuButton;
@end

@implementation OBAClassicDepartureView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.clipsToBounds = YES;

        UIView *leftLabelStackWrapper = [self.leftLabelStack oba_embedInWrapperView];
        leftLabelStackWrapper.mas_key = @"leftLabelStackWrapper";
        UIView *departureLabelStackWrapper = [self.departureLabelStack oba_embedInWrapperView];
        departureLabelStackWrapper.mas_key = @"departureLabelStackWrapper";
        [departureLabelStackWrapper setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [departureLabelStackWrapper mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.greaterThanOrEqualTo(@10);
        }];

        NSArray *views = @[leftLabelStackWrapper, departureLabelStackWrapper, self.contextMenuButton];
        UIStackView *horizontalStack = [[UIStackView alloc] initWithArrangedSubviews:views];
        horizontalStack.mas_key = @"horizontalStack";
        horizontalStack.translatesAutoresizingMaskIntoConstraints = NO;
        horizontalStack.axis = UILayoutConstraintAxisHorizontal;
        horizontalStack.distribution = UIStackViewDistributionFill;
        horizontalStack.spacing = OBATheme.compactPadding;
        [self addSubview:horizontalStack];

        [horizontalStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        [self.contextMenuButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@40);
            make.height.greaterThanOrEqualTo(@40);
        }];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            self.topLineLabel.backgroundColor = [UIColor redColor];
            self.middleLineLabel.backgroundColor = [UIColor greenColor];
            self.bottomLineLabel.backgroundColor = [UIColor blueColor];

            self.firstDepartureLabel.backgroundColor = [UIColor magentaColor];
            self.secondDepartureLabel.backgroundColor = [UIColor blueColor];
            self.thirdDepartureLabel.backgroundColor = [UIColor greenColor];
            departureLabelStackWrapper.backgroundColor = UIColor.brownColor;

            self.contextMenuButton.backgroundColor = [UIColor yellowColor];
        }
		
		if (@available(iOS 13.0, *)) {
			self.backgroundColor = [UIColor systemBackgroundColor];
		}
    }
    return self;
}

+ (UIView*)wrapDepartureLabel:(UILabel*)label {
    UIView *wrapper = [label oba_embedInWrapperViewWithConstraints:NO];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(wrapper);
    }];

    return wrapper;
}

#pragma mark - Table Cell 'Proxy' Methods

- (void)prepareForReuse {
    self.topLineLabel.text = nil;
    self.middleLineLabel.text = nil;
    self.bottomLineLabel.text = nil;
	
	if (@available(iOS 13, *)) { self.backgroundColor = [UIColor systemBackgroundColor]; }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    self.occupancyStatusView.isHighlighted = highlighted;
}

#pragma mark - Label Animation

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (!animated) {
        [self toggleLabelVisibilityForEditing:editing];
        return;
    }

    if (editing) {
        [self hideLabels];
    }
    else {
        [self showLabels];
    }
}

- (void)hideLabels {
    [OBAAnimation performAnimations:^{
        [self updateLabelAlpha:0.f];
    } completion:^(BOOL finished) {
        [self toggleLabelVisibilityForEditing:YES];
    }];
}

- (void)showLabels {
    // Make sure all of the labels are hidden.
    [self toggleLabelVisibilityForEditing:YES];

    // Make labels invisible.
    [self updateLabelAlpha:0.f];

    // Update hidden to NO
    [self toggleLabelVisibilityForEditing:NO];

    [OBAAnimation performAnimations:^{
        [self updateLabelAlpha:1.f];
    }];
}

- (void)updateLabelAlpha:(CGFloat)alpha {
    self.bottomLineLabel.alpha = alpha;
    self.firstDepartureLabel.alpha = alpha;
    self.secondDepartureLabel.alpha = alpha;
    self.thirdDepartureLabel.alpha = alpha;
}

- (void)toggleLabelVisibilityForEditing:(BOOL)editing {
    self.bottomLineLabel.hidden = editing;
    self.firstDepartureLabel.hidden = editing;
    self.secondDepartureLabel.hidden = editing;
    self.thirdDepartureLabel.hidden = editing;
}

#pragma mark - Row Logic

- (void)setDepartureRow:(OBADepartureRow *)departureRow {
    if (_departureRow == departureRow) {
        return;
    }

    _departureRow = [departureRow copy];

    self.topLineLabel.attributedText = _departureRow.attributedTopLine;
    self.topLineLabel.hidden = self.topLineLabel.attributedText.length == 0;

    self.middleLineLabel.attributedText = _departureRow.attributedMiddleLine;
    self.middleLineLabel.hidden = self.middleLineLabel.attributedText.length == 0;

    self.bottomLineLabel.attributedText = _departureRow.attributedBottomLine;
    self.bottomLineLabel.hidden = self.bottomLineLabel.attributedText.length == 0;

    [self applyUpcomingDeparture:[self departureRow].upcomingDepartures atIndex:0 toLabel:self.firstDepartureLabel];
    [self applyUpcomingDeparture:[self departureRow].upcomingDepartures atIndex:1 toLabel:self.secondDepartureLabel];
    [self applyUpcomingDeparture:[self departureRow].upcomingDepartures atIndex:2 toLabel:self.thirdDepartureLabel];

    // vertically center the one departure label if there is only one departure.
    // Otherwise vertically align them to the top.
    self.departureLabelSpacer.hidden = [self departureRow].upcomingDepartures.count == 1;

    self.occupancyStatusView.occupancyStatus = self.departureRow.expectedOccupancyStatus;
}

- (void)applyUpcomingDeparture:(NSArray<OBAUpcomingDeparture*>*)upcomingDepartures atIndex:(NSUInteger)index toLabel:(OBADepartureTimeLabel*)departureTimeLabel {
    if (upcomingDepartures.count > index) {
        departureTimeLabel.hidden = NO;

        OBAUpcomingDeparture *departure = upcomingDepartures[index];
        departureTimeLabel.accessibilityLabel = [OBADateHelpers formatAccessibilityLabelMinutesUntilDate:departure.departureDate];
        [departureTimeLabel setText:[OBADateHelpers formatMinutesUntilDate:departure.departureDate] forStatus:departure.departureStatus];
    }
    else {
        departureTimeLabel.hidden = YES;
    }
}

#pragma mark - Lazy UI Properties

- (OBAOccupancyStatusView*)occupancyStatusView {
    if (!_occupancyStatusView) {
        _occupancyStatusView = [[OBAOccupancyStatusView alloc] initWithImage:[UIImage imageNamed:@"silhouette"]];
        [_occupancyStatusView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_occupancyStatusView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _occupancyStatusView;
}

- (UIView*)occupancyStatusWrapper {
    if (!_occupancyStatusWrapper) {
        _occupancyStatusWrapper = [_occupancyStatusView oba_embedInWrapperViewWithConstraints:NO];
        _occupancyStatusWrapper.mas_key = @"occupancyWrapper";
        [_occupancyStatusView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.equalTo(_occupancyStatusWrapper);
        }];
    }
    return _occupancyStatusWrapper;
}

- (UIStackView*)leftLabelStack {
    if (!_leftLabelStack) {
        _leftLabelStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.topLineLabel, self.middleLineLabel, self.bottomLineLabel, [UIView new]]];
        _leftLabelStack.translatesAutoresizingMaskIntoConstraints = NO;
        _leftLabelStack.axis = UILayoutConstraintAxisVertical;
        _leftLabelStack.distribution = UIStackViewDistributionFill;
        _leftLabelStack.spacing = 0;
    }
    return _leftLabelStack;
}

+ (UILabel*)buildLineLabel {
    UILabel *lineLabel = [UILabel oba_autolayoutNew];
    lineLabel.numberOfLines = 0;
    [lineLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [lineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [lineLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

    return lineLabel;
}

- (UILabel*)topLineLabel {
    if (!_topLineLabel) {
        _topLineLabel = [UILabel oba_autolayoutNew];
        _topLineLabel.font = OBATheme.boldBodyFont;
        _topLineLabel.numberOfLines = 1;
        _topLineLabel.adjustsFontSizeToFitWidth = YES;
        _topLineLabel.minimumScaleFactor = 0.8f;
        [_topLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_topLineLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    }
    return _topLineLabel;
}

- (UILabel*)middleLineLabel {
    if (!_middleLineLabel) {
        _middleLineLabel = [self.class buildLineLabel];
    }
    return _middleLineLabel;
}

- (UILabel*)bottomLineLabel {
    if (!_bottomLineLabel) {
        _bottomLineLabel = [self.class buildLineLabel];
    }
    return _bottomLineLabel;
}

- (UIStackView*)departureLabelStack {
    if (!_departureLabelStack) {
        NSArray *labelStackViews = @[
                                     [OBAClassicDepartureView wrapDepartureLabel:self.firstDepartureLabel],
                                     [OBAClassicDepartureView wrapDepartureLabel:self.secondDepartureLabel],
                                     [OBAClassicDepartureView wrapDepartureLabel:self.thirdDepartureLabel],
                                     self.occupancyStatusView,
                                     self.departureLabelSpacer
                                     ];
        _departureLabelStack = [[UIStackView alloc] initWithArrangedSubviews:labelStackViews];
        _departureLabelStack.translatesAutoresizingMaskIntoConstraints = NO;
        _departureLabelStack.axis = UILayoutConstraintAxisVertical;
        _departureLabelStack.distribution = UIStackViewDistributionFill;
        _departureLabelStack.spacing = 0;
    }
    return _departureLabelStack;
}

- (OBADepartureTimeLabel*)firstDepartureLabel {
    if (!_firstDepartureLabel) {
        _firstDepartureLabel = [OBADepartureTimeLabel oba_autolayoutNew];
        _firstDepartureLabel.font = [OBATheme bodyFont];
        [_firstDepartureLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_firstDepartureLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    }
    return _firstDepartureLabel;
}

- (OBADepartureTimeLabel*)secondDepartureLabel {
    if (!_secondDepartureLabel) {
        _secondDepartureLabel = [OBADepartureTimeLabel oba_autolayoutNew];
        _secondDepartureLabel.font = [OBATheme footnoteFont];
        [_secondDepartureLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_secondDepartureLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    }
    return _secondDepartureLabel;
}

- (OBADepartureTimeLabel*)thirdDepartureLabel {
    if (!_thirdDepartureLabel) {
        _thirdDepartureLabel = [OBADepartureTimeLabel oba_autolayoutNew];
        _thirdDepartureLabel.font = [OBATheme footnoteFont];
        [_thirdDepartureLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_thirdDepartureLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    }
    return _thirdDepartureLabel;
}

- (UIView*)departureLabelSpacer {
    if (!_departureLabelSpacer) {
        _departureLabelSpacer = [UIView oba_autolayoutNew];
    }
    return _departureLabelSpacer;
}

- (UIButton*)contextMenuButton {
    if (!_contextMenuButton) {
        _contextMenuButton = [OBAUIBuilder contextMenuButton];
        _contextMenuButton.mas_key = @"contextMenuButton";
        _contextMenuButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contextMenuButton;
}

@end
