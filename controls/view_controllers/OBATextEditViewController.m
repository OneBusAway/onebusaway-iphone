//
//  OBATextEditViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBATextEditViewController.h"
#import <OBAKit/OBAKit.h>

static NSInteger const kMaximumCharacters = 255;

@interface OBATextEditViewController ()<UITextViewDelegate>
@property(nonatomic,strong) UITextView *textView;
@property(nonatomic,strong) UILabel *totalCharactersLabel;
@end

@implementation OBATextEditViewController
@dynamic text;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.textView.font = [OBATheme bodyFont];
    self.textView.frame = self.view.bounds;
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.textView.inputAccessoryView = ({
        CGFloat totallyArbitraryValueThatShouldWorkForEveryScenario = 30.f;
        UIView *accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), totallyArbitraryValueThatShouldWorkForEveryScenario)];
        accessoryView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(accessoryView.bounds, [OBATheme defaultPadding], 0)];
        label.textAlignment = NSTextAlignmentRight;
        [accessoryView addSubview:label];
        self.totalCharactersLabel = label;
        [self updateTotalCharactersLabel:self.textView.text.length];

        accessoryView;
    });
    [self.view addSubview:self.textView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OBAStrings.cancel style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OBAStrings.save style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.textView resignFirstResponder];
}

#pragma mark - Properties

- (void)setText:(NSString *)text {
    self.textView.text = text;
}

- (NSString*)text {
    return self.textView.text;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.length + range.location > textView.text.length) {
        return NO;
    }

    NSUInteger newLength = textView.text.length + text.length - range.length;

    BOOL isOK = newLength <= kMaximumCharacters;

    if (isOK) {
        [self updateTotalCharactersLabel:newLength];
    }

    return isOK;
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(id)sender {
    id delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(saveText:)]) {
        [delegate saveText:self.textView.text];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications

- (void)keyboardDidShow:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets insets = self.textView.contentInset;
    insets.bottom = kbSize.height;

    self.textView.contentInset = insets;
    self.textView.scrollIndicatorInsets = insets;
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;

    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Private

- (void)updateTotalCharactersLabel:(NSInteger)length {
    self.totalCharactersLabel.text = [NSString stringWithFormat:@"%@/%@", @(length), @(kMaximumCharacters)];
}

@end
