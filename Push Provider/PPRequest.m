//
//  PPRequest.m
//  Push Provider
//
//  Created by Alex Lebedev on 6/2/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import "PPRequest.h"
#import "GCDAsyncSocket.h"

typedef enum {
	APNSSockTagWrite,
	APNSSockTagRead
} APNSSockTag;

@interface PPRequest () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSData *message;
@property (nonatomic, assign) SecIdentityRef identity;
@property (nonatomic, assign) BOOL isSandbox;
@property (nonatomic, strong) PPRequestCompletion completion;

@end

@implementation PPRequest

- (id)initWithToken:(NSData*)token payload:(NSString*)payload identity:(SecIdentityRef)identity sandbox:(BOOL)isSandbox {
    self = [super init];
    if (self) {
        // building binary message
        NSMutableData *message = [NSMutableData data];
        
        uint8_t command = 1;
        [message appendBytes:&command length:sizeof(uint8_t)];
        
        uint32_t identifier = 123;
        [message appendBytes:&identifier length:sizeof(uint32_t)];
        
        uint32_t expiry = NSSwapInt((uint32_t)time(NULL)+86400);
        [message appendBytes:&expiry length:sizeof(uint32_t)];
        
        uint16_t tokenSize = NSSwapShort((uint16_t)token.length);
        [message appendBytes:&tokenSize length:sizeof(uint16_t)];
        [message appendData:token];
        
        NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
        uint16_t payloadDataSize = NSSwapShort((uint16_t)payloadData.length);
        [message appendBytes:&payloadDataSize length:sizeof(uint16_t)];
        [message appendData:payloadData];

        self.message = message;
        self.identity = identity;
        self.isSandbox = isSandbox;
    }
    return self;
}

- (void)runWithCompletion:(PPRequestCompletion)completion {
    self.completion = completion;

    NSLog(@"Running req");
    self.socket = [[GCDAsyncSocket alloc] init];
    [self.socket setDelegate:self delegateQueue:dispatch_get_current_queue()];
    NSError *error;
    NSString *host = self.isSandbox ? @"gateway.sandbox.push.apple.com" : @"gateway.push.apple.com";
    [_socket connectToHost:host onPort:2195 error:&error];

    if (error) {
        NSLog(@"Failed to connect: %@", error);
        return;
    }
    
    [_socket startTLS:@{(NSString*)kCFStreamSSLCertificates:@[(__bridge id)self.identity], (NSString*)kCFStreamSSLPeerName:host}];
}

- (void)complete {
    self.completion();
}

#pragma mark - GCDAsyncSocket Delegate

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"Writing data: %@", self.message);
	[sock writeData:self.message withTimeout:-1. tag:APNSSockTagWrite];
    
    // Always kill after 4 sec
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30. * NSEC_PER_SEC), dispatch_get_current_queue(), ^(void){
        NSLog(@"time to disconnect %@", sock);
		if ([sock isConnected])
            NSLog(@"disconnecting");
			[sock disconnect];
	});
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Did write data");
	if (tag == APNSSockTagWrite) {
        NSLog(@"reading");
		[sock readDataToLength:6 withTimeout:-1. tag:APNSSockTagRead];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"Read data: %@", data);
	if (tag == APNSSockTagRead) {
        /*
		uint8_t status;
		uint32_t identifier;
		
		[data getBytes:&status range:NSMakeRange(1, 1)];
		[data getBytes:&identifier range:NSMakeRange(2, 4)];
		
		NSString *desc;
		
		switch (status) {
			case 0:
				desc = @"No errors encountered";
				break;
			case 1:
				desc = @"Processing error";
				break;
			case 2:
				desc = @"Missing device token";
				break;
			case 3:
				desc = @"Missing topic";
				break;
			case 4:
				desc = @"Missing payload";
				break;
			case 5:
				desc = @"Invalid token size";
				break;
			case 6:
				desc = @"Invalid topic size";
				break;
			case 7:
				desc = @"Invalid payload size";
				break;
			case 8:
				desc = @"Invalid token";
				break;
			default:
				desc = @"None (unknown)";
				break;
		}
		
		_errorBlock(status, desc, identifier);
        */
        [sock disconnect];
	}
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"disconnected: %@", err);
    [self complete];
}

@end
