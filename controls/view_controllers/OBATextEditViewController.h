

@protocol OBATextEditViewControllerDelegate <NSObject>
- (void) saveText:(NSString*)text;
@end

@interface OBATextEditViewController : UIViewController

@property (nonatomic) id <OBATextEditViewControllerDelegate> delegate;
@property (nonatomic) BOOL readOnly;

+ (OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title;
+ (OBATextEditViewController*)pushOntoViewController:(UIViewController*)parent withText:(NSString*)text withTitle:(NSString*)title readOnly:(BOOL)readOnly;

- (IBAction)save:(id)sender;

@end
