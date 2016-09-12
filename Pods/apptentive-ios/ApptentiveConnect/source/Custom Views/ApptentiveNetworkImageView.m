//
//  ApptentiveNetworkImageView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNetworkImageView.h"

#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"


@interface ApptentiveNetworkImageView ()

@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLResponse *response;
@property (strong, nonatomic) NSMutableData *imageData;

@end


@implementation ApptentiveNetworkImageView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code
		_useCache = YES;
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.useCache = YES;
}

- (void)dealloc {
	[_connection cancel];
}

- (void)restartDownload {
	if (self.connection) {
		[self.connection cancel];
		self.connection = nil;
	}
	if (self.imageURL) {
		NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];

		NSURLCache *cache = [[Apptentive sharedConnection].backend imageCache];
		BOOL cacheHit = NO;
		if (cache) {
			NSCachedURLResponse *cachedResponse = [cache cachedResponseForRequest:request];
			if (cachedResponse && self.useCache) {
				UIImage *i = [UIImage imageWithData:cachedResponse.data];
				if (i) {
					self.image = i;
					cacheHit = YES;
				}
			}
		}

		if (!cacheHit) {
			self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
			[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			[self.connection start];
		}
	}
}

- (void)setImageURL:(NSURL *)anImageURL {
	if (_imageURL != anImageURL) {
		_imageURL = [anImageURL copy];
		[self restartDownload];
	}
}

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	if (aConnection == self.connection) {
		ApptentiveLogError(@"Unable to download image at %@: %@", self.imageURL, error);
		self.connection = nil;

		if ([self.delegate respondsToSelector:@selector(networkImageView:didFailWithError:)]) {
			[self.delegate networkImageView:self didFailWithError:error];
		}
	}
}

#pragma mark NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse {
	if (aConnection == self.connection) {
		self.imageData = [[NSMutableData alloc] init];
		self.response = [aResponse copy];
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	if (aConnection == self.connection) {
		[self.imageData appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	if (self.connection == aConnection) {
		UIImage *newImage = [UIImage imageWithData:self.imageData];
		if (newImage) {
			self.image = newImage;
			if (self.useCache) {
				NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
				NSURLCache *cache = [[Apptentive sharedConnection].backend imageCache];
				NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:self.response data:self.imageData userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
				[cache storeCachedResponse:cachedResponse forRequest:request];
				cachedResponse = nil;

				if ([self.delegate respondsToSelector:@selector(networkImageViewDidLoad:)]) {
					[self.delegate networkImageViewDidLoad:self];
				}
			}
		}
	}
}

@end
