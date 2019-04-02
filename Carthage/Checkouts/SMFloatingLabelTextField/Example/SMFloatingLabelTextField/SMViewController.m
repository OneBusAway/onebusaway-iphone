//
//  SMViewController.m
//  SMFloatingLabelTextField
//
//  Created by Michał Moskała on 06/30/2016.
//  Copyright (c) 2016 Michał Moskała. All rights reserved.
//

#import "SMViewController.h"
#import "SMFloatingLabelTextField.h"

@interface SMViewController ()
@property (nonatomic, weak) IBOutlet SMFloatingLabelTextField *addressTextField;
@property (nonatomic, weak) IBOutlet SMFloatingLabelTextField *lastNameTextField;
@end

@implementation SMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *lastNamePlaceholderAttributes = @{NSForegroundColorAttributeName: [UIColor magentaColor],
                                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0f weight:UIFontWeightBold],
                                                    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                    };
    NSAttributedString *lastNamePlaceholder = [[NSAttributedString alloc] initWithString:@"Last name" attributes:lastNamePlaceholderAttributes];
    
    [self.lastNameTextField setAttributedPlaceholder:lastNamePlaceholder];
    [self.addressTextField setText:@"NYC"];
}

@end
