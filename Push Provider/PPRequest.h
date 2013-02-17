//
//  PPRequest.h
//  Push Provider
//
//  Created by Alex Lebedev on 6/2/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^PPRequestCompletion)(void);

@interface PPRequest : NSObject

- (id)initWithToken:(NSData*)token payload:(NSString*)payload identity:(SecIdentityRef)identity sandbox:(BOOL)isSandbox;
- (void)runWithCompletion:(PPRequestCompletion)completion;

@end
