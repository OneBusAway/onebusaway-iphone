@protocol OBATextEditViewControllerDelegate

@end

@interface OBATextEditViewController : UIViewController {
	id _target;
	SEL _action;
	BOOL _keyboardShowing;
	CGFloat _nokeyboardHeight;
}

@property (nonatomic,assign) id target;
@property (nonatomic) SEL action;

+(OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title;

-(IBAction)save:(id)sender;

@end
