//
//  OBADepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADepartureCell.h"
#import "OBADepartureRow.h"
#import "OBATheme.h"
#import <Masonry/Masonry.h>
#import "OBADepartureCellHelpers.h"

#define kUseDebugColors NO

@interface OBADepartureCell ()
@property(nonatomic,strong) UIStackView *leftStackView;
@property(nonatomic,strong) UILabel *destinationLabel;
@property(nonatomic,strong) UILabel *minutesUntilNextDepartureLabel;
@property(nonatomic,strong) UILabel *nextDepartureTimeLabel;
@end

@implementation OBADepartureCell
@synthesize tableRow = _tableRow;

/*
 
 |                          |                                 |
 |    destinationLabel      |                                 |
 ---------------------------|  minutesUntilNextDepartureLabel |
 |  nextDepartureTimeLabel  |                                 |
 |                          |                                 |
 
 
 */

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {

        if (kUseDebugColors) {
            self.contentView.backgroundColor = [UIColor blueColor];
        }

        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        _destinationLabel = ({
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
            l.numberOfLines = 0;
            l.clipsToBounds = YES;
            l.minimumScaleFactor = 0.8f;
            l.font = [OBATheme bodyFont];

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor greenColor];
            }

            l;
        });
        
        _nextDepartureTimeLabel = ({
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
            l.font = [OBATheme bodyFont];

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor grayColor];
            }

            l;
        });

        _leftStackView = ({
            UIStackView *sv = [[UIStackView alloc] initWithArrangedSubviews:@[_destinationLabel, _nextDepartureTimeLabel]];
            sv.axis = UILayoutConstraintAxisVertical;
            sv.distribution = UIStackViewDistributionEqualSpacing;
            sv;
        });
        [self.contentView addSubview:_leftStackView];

        _minutesUntilNextDepartureLabel = ({
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
            l.textAlignment = NSTextAlignmentRight;
            l.font = [OBATheme subtitleFont];

            if (kUseDebugColors) {
                l.backgroundColor = [UIColor yellowColor];
            }

            l;
        });
        [self.contentView addSubview:_minutesUntilNextDepartureLabel];
    }

    return self;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.destinationLabel.text = nil;
    self.minutesUntilNextDepartureLabel.text = nil;
    self.nextDepartureTimeLabel.text = nil;
    self.nextDepartureTimeLabel.textColor = [UIColor blackColor]; // TODO: [OBATheme textColor]; or something!
    self.minutesUntilNextDepartureLabel.textColor = [UIColor blackColor]; // TODO: [OBATheme textColor]; or something!
}

#pragma mark - Auto Layout

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {

    UIView *superview = self.contentView;

    [self.minutesUntilNextDepartureLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.right.and.bottom.equalTo(superview);
        make.height.greaterThanOrEqualTo(@44).priorityMedium();
    }];

    [self.leftStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.and.bottom.equalTo(superview).insets(UIEdgeInsetsMake(0, self.layoutMargins.left, 0, 0));
        make.right.equalTo(self.minutesUntilNextDepartureLabel.mas_left);
    }];

    // this has to come at the end.
    [super updateConstraints];
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {
    
    OBAGuardClass(tableRow, OBADepartureRow) else {
        return;
    }
    
    _tableRow = [tableRow copy];
    
    self.destinationLabel.text = [self departureRow].destination;
    self.minutesUntilNextDepartureLabel.text = [self departureRow].formattedMinutesUntilNextDeparture;
    self.nextDepartureTimeLabel.attributedText = [OBADepartureCellHelpers attributedDepartureTime:[self departureRow].formattedNextDepartureTime
                                                                                       statusText:[self departureRow].statusText
                                                                                  departureStatus:[self departureRow].departureStatus];

    if ([self departureRow].minutesUntilDeparture >= 0) {
        self.minutesUntilNextDepartureLabel.textColor = [OBADepartureCellHelpers colorForStatus:[self departureRow].departureStatus];
    }
    else {
        // If the vehicle has already departed, gray this cell out.
        self.destinationLabel.textColor = [UIColor darkGrayColor];
        self.minutesUntilNextDepartureLabel.textColor = [UIColor darkGrayColor];
        self.nextDepartureTimeLabel.textColor = [UIColor darkGrayColor];
    }
}

- (OBADepartureRow*)departureRow {
    return (OBADepartureRow*)[self tableRow];
}

@end
