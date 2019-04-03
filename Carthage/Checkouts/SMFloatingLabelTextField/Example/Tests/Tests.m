//
//  SMFloatingLabelTextFieldTests.m
//  SMFloatingLabelTextFieldTests
//
//  Created by Michał Moskała on 06/30/2016.
//  Copyright (c) 2016 Michał Moskała. All rights reserved.
//

// https://github.com/kiwi-bdd/Kiwi

#import <Kiwi/Kiwi.h>
@import SMFloatingLabelTextField;

SPEC_BEGIN(InitialTests)

describe(@"Tests", ^{

    __block SMFloatingLabelTextField* sut = nil;
    
    beforeEach(^{
        sut = [[SMFloatingLabelTextField alloc] initWithFrame:CGRectMake(0, 0, 100.0f, 50.0f)];
    });
    
    context(@"field is initialized", ^{
        it(@"should have default configuration", ^{
            [[sut.floatingLabelPassiveColor should] equal:[UIColor lightGrayColor]];
            [[sut.floatingLabelActiveColor should] equal:[UIColor blueColor]];
            [[sut.floatingLabelFont should] equal:[UIFont systemFontOfSize:12.0]];
        });
    });
});

SPEC_END

