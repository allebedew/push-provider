//
//  NSObject+DataTransformers.h
//  Push Provider
//
//  Created by Alex Lebedev on 17/2/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DataTransformers)

- (NSData*)apnsTokenData;

@end
