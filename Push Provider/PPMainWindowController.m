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
#import "NSObject+DataTransformers.h"

@interface PPMainWindowController ()

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *payload;
@property (nonatomic, readonly) NSString *identityName;
@property (nonatomic, readonly) NSUInteger payloadSize;
@property (nonatomic, assign) SecIdentityRef identity;

- (IBAction)showIdentityChooser:(id)sender;
- (IBAction)sendPushNotification:(id)sender;

@end

@implementation PPMainWindowController

- (void)awakeFromNib {
    self.token = @"ff211390 ab00f780 0ab12e4f 2194e8bb df208b00 6cf4c199 af04a809 fcb7516a";
    self.payload = @"{\"aps\":{\"alert\":\"You have mail!\",\"badge\":1,\"sound\":\"default\"}}";
    self.identityName = [[NSUserDefaults standardUserDefaults] objectForKey:@"Identity"];
}

#pragma mark - Identity

+ (NSSet*)keyPathsForValuesAffectingIdentityName {
    return [NSSet setWithObject:@"identity"];
}

- (NSString*)identityName {
    if (self.identity) {
        SecCertificateRef cert = NULL;
        if (SecIdentityCopyCertificate(self.identity, &cert) == noErr) {
            CFStringRef commonName = NULL;
            SecCertificateCopyCommonName(cert, &commonName);
            CFRelease(cert);
            return (__bridge_transfer NSString *)commonName;
        }
    }
    return nil;
}

- (void)setIdentityName:(NSString *)identityName {
    NSLog(@"set identity: %@", identityName);
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

- (void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode != NSFileHandlingPanelOKButton) {
        return;
    }
    [self willChangeValueForKey:@"identityName"]; // force UI update
    self.identity = [SFChooseIdentityPanel sharedChooseIdentityPanel].identity;
    [self didChangeValueForKey:@"identityName"];
    [[NSUserDefaults standardUserDefaults] setObject:self.identityName forKey:@"Identity"];
}
/*
- (IBAction)exportIdentity:(id)sender {
    if (self.APNS.identity != NULL) {
        CFDataRef data = NULL;
        uuit_t
        
        // Generate a random passphrase and filename
        NSString *passphrase = [[NSUUID UUID] UUIDString];
        NSString *PKCS12FileName = [[NSUUID UUID] UUIDString];
        
        // Export to PKCS12
        SecItemImportExportKeyParameters keyParams = {
            SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION,
            0,
            (__bridge CFStringRef)passphrase,
            NULL,
            NULL,
            NULL,
            NULL,
            (__bridge CFArrayRef)@[@(CSSM_KEYATTR_PERMANENT)]
        };
        
        if (noErr == SecItemExport(self.APNS.identity,
                                   kSecFormatPKCS12,
                                   0,
                                   &keyParams,
                                   &data)) {
            
            NSSavePanel *panel = [NSSavePanel savePanel];
            [panel setPrompt:@"Export"];
            [panel setNameFieldLabel:@"Export As:"];
            [panel setNameFieldStringValue:@"cert.pem"];
            
            [panel beginSheetModalForWindow:self.window
                          completionHandler:^(NSInteger result) {
                              if (result == NSFileHandlingPanelCancelButton)
                                  return;
                              
                              // Write to temp file
                              NSURL *tempURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                              tempURL = [tempURL URLByAppendingPathComponent:PKCS12FileName];
                              
                              [(__bridge NSData *)data writeToURL:tempURL atomically:YES];
                              
                              // convert with openssl to pem
                              NSTask *task = [NSTask new];
                              [task setLaunchPath:@"/bin/sh"];
                              [task setArguments:@[
                               @"-c",
                               [NSString stringWithFormat:@"/usr/bin/openssl pkcs12 -in %@ -out %@ -nodes", tempURL.path, panel.URL.path]
                               ]];
                              
                              // Remove temp file on completion
                              [task setTerminationHandler:^(NSTask *task) {
                                  [[NSFileManager defaultManager] removeItemAtURL:tempURL error:NULL];
                              }];
                              
                              NSPipe *pipe = [NSPipe pipe];
                              [pipe.fileHandleForWriting writeData:[[NSString stringWithFormat:@"%@\n", passphrase] dataUsingEncoding:NSUTF8StringEncoding]];
                              [task setStandardInput:pipe];
                              
                              [task launch];
                          }];
        }
    }
}
*/
#pragma mark -

+ (NSSet*)keyPathsForValuesAffectingPayloadSize {
    return [NSSet setWithObject:@"payload"];
}

- (NSUInteger)payloadSize {
    return [self.payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

- (IBAction)sendPushNotification:(id)sender {
    __block PPRequest *request = [[PPRequest alloc] initWithToken:self.token.apnsTokenData payload:self.payload identity:self.identity sandbox:YES];
    [request runWithCompletion:^{
        NSLog(@"req complete");
        request = nil;
    }];
}

@end
