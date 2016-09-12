//
//  ApptentiveURLConnection_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveURLConnection.h"


@interface ApptentiveURLConnection ()
/*! It's important nobody but ATURLConnection and ApptentiveionChannel call this
    selector. */
- (void)cancel;
@end
