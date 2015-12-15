
NS_ASSUME_NONNULL_BEGIN

@protocol OBATextEditViewControllerDelegate<NSObject>
- (void)saveText:(NSString*)text;
@end

@interface OBATextEditViewController : UIViewController
@property(nonatomic,weak) id<OBATextEditViewControllerDelegate> delegate;
@property(nonatomic,copy) NSString *text;
@end

NS_ASSUME_NONNULL_END