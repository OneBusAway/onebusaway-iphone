/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAUploadManager.h"
#import "OBAUploadViewController.h"
#import "OBAProgressIndicatorView.h"


@implementation OBAUploadViewController

@synthesize tracesOnDiskLabel = _tracesOnDiskLabel;
@synthesize tracesOnServerLabel = _tracesOnServerLabel;
@synthesize tracesToUploadLabel = _tracesToUploadLabel;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if( self = [super initWithNibName:@"OBAUploadView" bundle:[NSBundle mainBundle]] ) {
		_uploadManager = [[OBAUploadManager alloc] init];
		_uploadManager.jsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:appContext.obaDataSourceConfig];
		
		NSMutableArray * items = [[NSMutableArray alloc] init];
		
		UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(onAddBookmarkButton:)];
		[items addObject:spaceItem];
		[spaceItem release];
		
		OBAProgressIndicatorView * view = [OBAProgressIndicatorView viewFromNib];
		UIBarButtonItem * progressItem = [[UIBarButtonItem alloc] initWithCustomView:view];
		[items addObject:progressItem];
		[progressItem release];
		
		spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(onAddBookmarkButton:)];
		[items addObject:spaceItem];
		[spaceItem release];
		
		self.toolbarItems = items;
	}
	return self;
}

- (void)dealloc {
	[_uploadManager release];
	
	[_tracesOnDiskLabel release];
	[_tracesOnServerLabel release];
	[_tracesToUploadLabel release];
	
    [super dealloc];
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[_uploadManager addObserver:self forKeyPath:@"tracesOnDisk" options:NSKeyValueObservingOptionNew context:nil];
	[_uploadManager addObserver:self forKeyPath:@"tracesOnServer" options:NSKeyValueObservingOptionNew context:nil];
	[_uploadManager addObserver:self forKeyPath:@"tracesToUpload" options:NSKeyValueObservingOptionNew context:nil];
	
	[_uploadManager start];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[_uploadManager removeObserver:self forKeyPath:@"tracesOnDisk"];
	[_uploadManager removeObserver:self forKeyPath:@"tracesOnServer"];
	[_uploadManager removeObserver:self forKeyPath:@"tracesToUpload"];

	[_uploadManager stop];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

	if ([keyPath isEqual:@"tracesOnDisk"]) {
		_tracesOnDiskLabel.text = _uploadManager.tracesOnDisk;
	}
	else if ([keyPath isEqual:@"tracesOnServer"]) {
		_tracesOnServerLabel.text = _uploadManager.tracesOnServer;
	}
	else if ([keyPath isEqual:@"tracesToUpload"]) {
		_tracesToUploadLabel.text = _uploadManager.tracesToUpload;
	}
}

-(IBAction)onUploadButton:(id)source {
	[_uploadManager startUploading];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [OBANavigationTarget target:OBANavigationTargetTypeActivityUpload];
}

@end
