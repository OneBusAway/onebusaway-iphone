//
//  OBAInfoViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAInfoViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

- (void)openContactUs;
- (void)openSettings;
- (void)openAgencies;

@property(nonatomic,strong) IBOutlet UIView *headerView;
@property(nonatomic,strong) IBOutlet UITableView *tableView;
@end

NS_ASSUME_NONNULL_END