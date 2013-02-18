//
//  NSObject+DataTransformers.m
//  Push Provider
//
//  Created by Alex Lebedev on 17/2/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import "NSObject+DataTransformers.h"

@implementation NSString (DataTransformers)

- (NSData*)apnsTokenData {
    NSMutableData *data = [NSMutableData data];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    unsigned int word;
    while ([scanner scanHexInt:&word]) {
        unsigned int invWord = NSSwapInt(word);
        [data appendBytes:&invWord length:sizeof(invWord)];
    }
    if (data.length != 32) {
        return nil;
    }
    return data;
}

@end
