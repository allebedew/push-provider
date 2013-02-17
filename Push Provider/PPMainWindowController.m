//
//  PPMainWindowController.m
//  Push Provider
//
//  Created by Alex Lebedev on 31/1/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import "PPMainWindowController.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import "PPRequest.h"

@interface PPMainWindowController ()

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *payload;
@property (nonatomic, strong) NSString *identityName;
@property (nonatomic, assign) SecIdentityRef identity;
@property (nonatomic, strong) PPRequest *request;

- (IBAction)showIdentityChooser:(id)sender;
- (IBAction)sendPushNotification:(id)sender;

@end

@implementation PPMainWindowController

- (void)awakeFromNib {
    self.token = @"ff211390 ab00f780 0ab12e4f 2194e8bb df208b00 6cf4c199 af04a809 fcb7516a";
    self.payload = @"{\"aps\":{\"alert\":\"You have mail!\"}}";
}

- (NSData*)dataWithHexString:(NSString*)string {
    NSMutableData *data = [NSMutableData data];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    unsigned int word;
    while ([scanner scanHexInt:&word]) {
        unsigned int invWord = NSSwapInt(word);
        [data appendBytes:&invWord length:sizeof(invWord)];
    }
    return data;
}

- (IBAction)showIdentityChooser:(id)sender {
	SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
	[panel setAlternateButtonTitle:@"Cancel"];
    
    NSArray *resIdentities = @[];
    NSDictionary *query = @{(id)kSecClass:(id)kSecClassIdentity, (id)kSecMatchLimit:(id)kSecMatchLimitAll, (id)kSecReturnRef:(id)kCFBooleanTrue};
	CFArrayRef identities = NULL;
	if (noErr == SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&identities)) {
		resIdentities = (__bridge_transfer NSArray*)identities;
	}
    
	[panel beginSheetForWindow:self.window modalDelegate:self didEndSelector:@selector(chooseIdentityPanelDidEnd:returnCode:contextInfo:) contextInfo:nil identities:resIdentities message:@"Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"];
}

- (IBAction)sendPushNotification:(id)sender {
    self.request = [[PPRequest alloc] initWithToken:[self dataWithHexString:self.token] payload:self.payload identity:self.identity sandbox:YES];
    [self.request run];
}

#pragma mark - SFChooseIdentityPanel Delegate

- (void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode != NSFileHandlingPanelOKButton) {
        return;
    }
    self.identity = [SFChooseIdentityPanel sharedChooseIdentityPanel].identity;
    
    SecCertificateRef cert = NULL;
    if (noErr == SecIdentityCopyCertificate(self.identity, &cert)) {
        CFStringRef commonName = NULL;
        SecCertificateCopyCommonName(cert, &commonName);
        CFRelease(cert);
        self.identityName = (__bridge_transfer NSString *)commonName;
    } else {
        self.identityName = @"None";
    }

}


@end
