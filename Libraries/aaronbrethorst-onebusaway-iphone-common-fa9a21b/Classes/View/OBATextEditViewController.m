//
//  OBATextEditViewController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 8/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBATextEditViewController.h"


@interface OBATextEditViewController (Private)

-(UITextView*) textView;
-(void)keyboardDidShow:(NSNotification*)notification;
-(void)keyboardDidHide:(NSNotification*)notification;

@end


@implementation OBATextEditViewController

@synthesize target = _target;
@synthesize action = _action;
@synthesize readOnly = _readOnly;

+(OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title {
    return [self pushOntoViewController:parent withText:text withTitle:title readOnly:NO];
}

+(OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title readOnly:(BOOL)readOnly {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBATextEditViewController" owner:parent options:nil];
    OBATextEditViewController* controller = wired[0];
    [controller setTitle:title];
    
    UITextView * textView = [controller textView];
    [textView setText:text];
    
    if( readOnly ) {
        [controller textView].editable = NO;
        controller.navigationItem.rightBarButtonItem = nil;
    }
    
    controller.readOnly = readOnly;
    
    [[parent navigationController] pushViewController:controller animated:YES];
    return controller;
}


#pragma mark UIViewController

-(void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name: UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    if( ! _readOnly ) {
        [[self navigationController] setToolbarHidden:YES animated:YES];
        [[self textView] becomeFirstResponder];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    
}

-(void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark Actions

-(IBAction)save:(id)sender {
    if( _target && _action && [_target respondsToSelector:_action] ) {
// note: I think that silencing warnings like this is gross.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_action withObject:[[self textView] text]];
#pragma clang diagnostic pop
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation OBATextEditViewController (Private)


-(UITextView*)textView {
    return (UITextView*)[self view];
}

-(void)keyboardDidShow:(NSNotification*)notification {
    if (_keyboardShowing) {return;}
    
    NSValue* bounds = [notification userInfo][UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = bounds.CGRectValue.size;
    CGRect frame = self.view.frame;
    _nokeyboardHeight = frame.size.height;
    frame.size.height = _nokeyboardHeight - keyboardSize.height;
    self.view.frame = frame;
    _keyboardShowing = YES;
}

-(void)keyboardDidHide:(NSNotification*)notification {
    if (!_keyboardShowing) {return;}
    CGRect frame = [self view].frame;
    frame.size.height = _nokeyboardHeight;
    [[self view] setFrame:frame];
    _keyboardShowing = NO;    
}

@end

