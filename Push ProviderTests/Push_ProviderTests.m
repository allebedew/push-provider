//
//  Push_ProviderTests.m
//  Push ProviderTests
//
//  Created by Alex Lebedev on 17/2/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import "Push_ProviderTests.h"
#import "NSObject+DataTransformers.h"

@implementation Push_ProviderTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testApnsTokenData {
    NSString *description = @"<ff211390 ab00f780 0ab12e4f 2194e8bb df208b00 6cf4c199 af04a809 fcb7516a>";
    NSString *token1 = @"ff211390 ab00f780 0ab12e4f 2194e8bb df208b00 6cf4c199 af04a809 fcb7516a";
    STAssertTrue([token1.apnsTokenData.description isEqual:description], @"Plain token decription");
}

@end