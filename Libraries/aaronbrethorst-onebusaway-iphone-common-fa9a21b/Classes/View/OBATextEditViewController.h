@protocol OBATextEditViewControllerDelegate

@end

@interface OBATextEditViewController : UIViewController {
    id __weak _target;
    SEL _action;
    BOOL _keyboardShowing;
    CGFloat _nokeyboardHeight;
    BOOL _readOnly;
}

@property (nonatomic,weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic) BOOL readOnly;

+(OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title;
+(OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title readOnly:(BOOL)readOnly;

-(IBAction)save:(id)sender;

@end
