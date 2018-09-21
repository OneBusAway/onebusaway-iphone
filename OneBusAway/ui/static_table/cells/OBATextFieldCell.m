//
//  OBATextFieldCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/24/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATextFieldCell.h"
#import "OBATextFieldRow.h"
@import Masonry;
#import "SMFloatingLabelTextField.h"

#define kDebugColors NO

@interface OBATextFieldCell ()<UITextFieldDelegate>
@property(nonatomic,strong) SMFloatingLabelTextField *textField;
@end

@implementation OBATextFieldCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _textField = [[SMFloatingLabelTextField alloc] initWithFrame:CGRectZero];
        _textField.userInteractionEnabled = YES;
        _textField.delegate = self;
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        [self.contentView addSubview:_textField];

        UIEdgeInsets layoutMargins = self.layoutMargins;
        layoutMargins.bottom = OBATheme.compactPadding;
        layoutMargins.top = OBATheme.compactPadding;

        [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(layoutMargins);
            make.height.greaterThanOrEqualTo(@44).priorityMedium();
        }];

        if (kDebugColors) {
            self.contentView.backgroundColor = [UIColor magentaColor];
            _textField.backgroundColor = [UIColor greenColor];
        }
    }

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.textField.text = nil;
    self.textField.placeholder = nil;
}

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBATextFieldRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.textField.placeholder = [self textFieldRow].labelText;
    self.textField.text = [self textFieldRow].textFieldText;
    self.textField.keyboardType = [self textFieldRow].keyboardType;
    self.textField.autocapitalizationType = [self textFieldRow].autocapitalizationType;
    self.textField.autocorrectionType = [self textFieldRow].autocorrectionType;
    self.textField.returnKeyType = [self textFieldRow].returnKeyType;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {

    NSMutableDictionary *dict = [self textFieldRow].model;
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }

    // We rely on duck typing to ensure that we're not going to shoot
    // ourselves in the foot here, by muddling about in a class cluster.
    if (![dict respondsToSelector:@selector(setObject:forKeyedSubscript:)]) {
        return;
    }

    if (![self textFieldRow].dataKey) {
        return;
    }

    if (!textField.text) {
        return;
    }

    dict[[self textFieldRow].dataKey] = textField.text;
}

#pragma mark - Private

- (OBATextFieldRow*)textFieldRow {
    return (OBATextFieldRow*)self.tableRow;
}
@end
