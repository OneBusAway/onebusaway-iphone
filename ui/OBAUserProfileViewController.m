//
//  OBAUserProfileViewController.m
//  org.onebusaway.iphone
//
//  Created by Kevin Pham on 3/22/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAUserProfileViewController.h"


@interface OBAUserProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *userPoints;
@property (weak, nonatomic) IBOutlet UIView *profileBox;
@property (weak, nonatomic) IBOutlet UITableView *userActivity;
@property(strong) NSArray *bookmarks;
@property (weak, nonatomic) IBOutlet UICollectionView *badgeCollectionView;
@property (weak, nonatomic) IBOutlet UIImageView *picture1;
@property (weak, nonatomic) IBOutlet UIImageView *picture2;


@end

@implementation OBAUserProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
  self.badgeCollectionView.delegate = self;
  
  self.view.backgroundColor = OBAGREEN;
  
  self.profileBox.layer.cornerRadius = 20;
  CGRect profileFrame = [self.view frame];
  profileFrame.origin.x = 25.0f;
  profileFrame.origin.y = 100.0f;
  [self.view addSubview:_profileBox];
  
  //User picture set-up
  self.userPicture.layer.cornerRadius = 50;
  self.userPicture.layer.masksToBounds = true;
  self.userPicture.layer.borderColor = [[UIColor whiteColor] CGColor];
  self.userPicture.layer.borderWidth = 4;
  self.userPicture.contentMode = UIViewContentModeScaleAspectFill;
  self.userPicture.image = [UIImage imageNamed:@"juju.jpg"];
  
  self.userName.text = @"Jack Spade"; //replace with username
  
  //THIS WILL BE DELETED AND REPLACED WITH COLLECTION VIEW
  self.picture1.layer.cornerRadius = 25;
  self.picture1.layer.masksToBounds = true;
  
  self.picture2.layer.cornerRadius = 25;
  self.picture2.layer.masksToBounds = true;
  
  
  //Camera button
  UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed)];
  self.navigationItem.rightBarButtonItem = cameraButton;
}

//Camera Button Pressed
-(void)cameraButtonPressed {
  UIImagePickerController *picturePicker = [[UIImagePickerController alloc] init];
  picturePicker.delegate = self;
  picturePicker.allowsEditing = true;
  picturePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  
  [self.navigationController presentViewController:picturePicker animated:true completion:nil];
  
}

#pragma mark UserActivity CollectionView
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return 5;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell = [[UICollectionViewCell alloc] init];
  return cell;
}

//MARK: Image Picker Controller Delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  
  UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
  self.userPicture.image = chosenImage;
  
  //Save selected image locally
  NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"MyPicture.jpg"];
  
  NSData *imageData = UIImageJPEGRepresentation(chosenImage, 0.85);
  [imageData writeToFile:filePath atomically:YES];
  
  [picker dismissViewControllerAnimated:YES completion:NULL];
  
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
  
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end