//
//  ApptentiveConnectionChannel.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveURLConnection;


@interface ApptentiveConnectionChannel : NSObject
@property (assign, nonatomic) NSUInteger maximumConnections;

- (void)update;
- (void)addConnection:(ApptentiveURLConnection *)connection;
- (void)cancelAllConnections;
- (void)cancelConnection:(ApptentiveURLConnection *)connection;
@end
