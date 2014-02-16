//
//  OBATextEditViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBATextEditViewController.h"


@interface OBATextEditViewController ()
@property (nonatomic) UITextView *textView;
@property (nonatomic) BOOL keyboardShowing;
@property (nonatomic) CGFloat nokeyboardHeight;
- (void)keyboardDidShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

@end


@implementation OBATextEditViewController

+ (OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title {
    return [self pushOntoViewController:parent withText:text withTitle:title readOnly:NO];
}

+ (OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title readOnly:(BOOL)readOnly {
    NSArray *wired = [[NSBundle mainBundle] loadNibNamed:@"OBATextEditViewController" owner:parent options:nil];
    OBATextEditViewController *controller = wired[0];
    [controller setTitle:title];
    
    UITextView *textView = controller.textView;
    [textView setText:text];
    
    if(readOnly) {
        controller.textView.editable = NO;
        controller.navigationItem.rightBarButtonItem = nil;
    }
    controller.readOnly = readOnly;
    
    [parent.navigationController pushViewController:controller animated:YES];
    return controller;
}


#pragma mark UIViewController

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name: UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!self.readOnly) {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.textView becomeFirstResponder];
    }
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark Actions

- (IBAction)save:(id)sender {
    if([self.delegate respondsToSelector:@selector(saveText:)] ) {
        [self.delegate saveText:self.textView.text];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (UITextView*)textView {
    return (UITextView*)self.view;
}

- (void)keyboardDidShow:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
}

- (void)keyboardWillHide:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
}
@end

