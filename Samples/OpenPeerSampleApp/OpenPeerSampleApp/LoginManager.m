/*
 
 Copyright (c) 2012, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import "LoginManager.h"


#import "OpenPeer.h"
#import "OpenPeerUser.h"
//Utility
#import "XMLWriter.h"
#import "Utility.h"
#import "Constants.h"
//Managers
#import "ContactsManager.h"
//SDK
#import "OpenPeerSDK/HOPAccount.h"
#import "OpenPeerSDK/HOPIdentity.h"
#import "OpenPeerSDK/HOPTypes.h"
//Delegates
#import "StackDelegate.h"
//View Controllers
#import "MainViewController.h"
#import "LoginViewController.h"
#import "ActivityIndicatorViewController.h"
#import "WebLoginViewController.h"

@interface LoginManager ()

@property (nonatomic) BOOL isLogin;
@property (nonatomic) BOOL isAssociation;

@property (nonatomic, weak) HOPIdentity* loginIdentity;
@end


@implementation LoginManager

/**
 Retrieves singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
+ (id) sharedLoginManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

/**
 Initialize singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
- (id) init
{
    self = [super init];
    if (self)
    {
        self.isLogin  = NO;
        self.isAssociation = NO;
    }
    return self;
}

- (WebLoginViewController *)webLoginViewController
{
    if (!_webLoginViewController)
    {
        _webLoginViewController = [[WebLoginViewController alloc] init];
        if (_webLoginViewController)
            _webLoginViewController.view.hidden = YES;
    }
    
    return _webLoginViewController;
}
/**
 This method will show login window in case user data does not exists on device, or start relogin automatically if information are available.
 @return Singleton object of the Contacts Manager.
 */
- (void) login
{
    //If peer file doesn't exists, show login view, otherwise start relogin
    if ([[[OpenPeerUser sharedOpenPeerUser] privatePeerFile] length] == 0)
    {
        [[[OpenPeer sharedOpenPeer] mainViewController] showLoginView];
        self.isLogin = YES;
    }
    else
    {
        [self startRelogin];
    }
}

- (void) loginUsingDomain:(NSString*) identityProviderDomain
{
    
}

/**
 Logout from the current account.
 */
- (void) logout
{    
    //Delete all cookies.
    [Utility removeCookiesAndClearCredentials];
    
    //Delete user data stored on device.
    [[OpenPeerUser sharedOpenPeerUser] deleteUserData];
    
    //Remove all contacts
    [[[ContactsManager sharedContactsManager] contactArray] removeAllObjects];
    //[[[ContactsManager sharedContactsManager] contactsDictionaryByProvider] removeAllObjects];
    
    //Call to the SDK in order to shutdown Open Peer engine.
    [[HOPAccount sharedAccount] shutdown];
    
    //Return to the login page.
    [[[OpenPeer sharedOpenPeer] mainViewController] showLoginView];
    
}

- (void) startLoginUsingIdentityURI:(NSString*) identityURI
{
    NSLog(@"Identity login started");
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Getting identity login url ..." inView:[[[[OpenPeer sharedOpenPeer] mainViewController] loginViewController] view]];
    
    HOPIdentity* hopIdentity = [HOPIdentity loginWithDelegate:(id<HOPIdentityDelegate>)[[OpenPeer sharedOpenPeer] identityDelegate] redirectAfterLoginCompleteURL:afterLoginCompleteURL identityURIOridentityBaseURI:identityURI identityProviderDomain:identityProviderDomain];
    //[((OpenPeerUser*)[OpenPeerUser sharedOpenPeerUser]).associatedIdentities setObject:hopIdentity forKey:identityURI];
    
    //if (hopIdentity)
        //[[HOPAccount sharedAccount] loginWithAccountDelegate:(id<HOPAccountDelegate>)[[OpenPeer sharedOpenPeer] accountDelegate] conversationThreadDelegate:(id<HOPConversationThreadDelegate>) [[OpenPeer sharedOpenPeer] conversationThreadDelegate]  callDelegate:(id<HOPCallDelegate>) [[OpenPeer sharedOpenPeer] callDelegate]  peerContactServiceDomain:identityProviderDomain identity:hopIdentity];
}


/**
 Initiates relogin procedure.
 */
- (void) startRelogin
{
    NSLog(@"Relogin started");
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Relogin ..." inView:[[[OpenPeer sharedOpenPeer] mainViewController] view]];
    
    [[HOPAccount sharedAccount] reloginWithAccountDelegate:(id<HOPAccountDelegate>) [[OpenPeer sharedOpenPeer] accountDelegate] conversationThreadDelegate:(id<HOPConversationThreadDelegate>)[[OpenPeer sharedOpenPeer] conversationThreadDelegate]  callDelegate:(id<HOPCallDelegate>)[[OpenPeer sharedOpenPeer] callDelegate] peerFilePrivate:[[OpenPeerUser sharedOpenPeerUser] privatePeerFile]  peerFilePrivateSecret:[[OpenPeerUser sharedOpenPeerUser] privatePeerFileSecret]];
    /*
    //Information about login identity.
    HOPIdentityInfo* identityInfoLI = [[HOPIdentityInfo alloc] init];
    identityInfoLI.type = HOPProvisioningAccountIdentityTypeLinkedInID;
    HOPIdentityInfo* identityInfoFB = [[HOPIdentityInfo alloc] init];
    identityInfoFB.type = HOPProvisioningAccountIdentityTypeFacebookID;
    
    //Call to the SDK in order to setup delegate for the OAuth relogin process, and to initiate OAuth relogin. This method call also requires that user will provide information which is saved after the last successful login process. This information is required in order to successfuly access existing account and fetch private peer password.
    [[HOPProvisioningAccount sharedProvisioningAccount] reloginWithProvisioningAccountDelegate:(id<HOPProvisioningAccountDelegate>)[[OpenPeer sharedOpenPeer] provisioningAccountDelegate] provisioningURI:provisioningURI deviceToken:@"" userID:[[OpenPeerUser sharedOpenPeerUser] userId] accountSalt:[[OpenPeerUser sharedOpenPeerUser] accountSalt] passwordNonce:[[OpenPeerUser sharedOpenPeerUser] passwordNonce] password:[[OpenPeerUser sharedOpenPeerUser] peerFilePassword] privatePeerFile:[[OpenPeerUser sharedOpenPeerUser] privatePeerFile] lastProfileUpdatedTimestamp:[[OpenPeerUser sharedOpenPeerUser] lastProfileUpdateTimestamp]  previousIdentities:[NSArray arrayWithObjects: identityInfoFB, nil ]];*/
}

/**
 Handles core event that login URL is available.
 @param url NSString Login URL.
 */
- (void) onLoginUrlReceived:(NSString*) url forIdentity:(HOPIdentity*) identity
{
    self.loginIdentity = identity;
    
    //Login url is received. Remove activity indicator
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    
    if ([url length] > 0)
        [self.webLoginViewController openLoginUrl:url];    
}

- (void) onOuterFrameLoaded
{
//    NSString* innerFRame = @"http://example-unstable.hookflash.me/inner.html";
//    NSString* innerFRame2 = [self.loginIdentity getIdentityLoginURL];
    NSString* jsMethod = [NSString stringWithFormat:@"initInnerFrame(\'%@\')",[self.loginIdentity getIdentityLoginURL]];
    [self.webLoginViewController passMessageToJS:jsMethod];;
}

- (void) onMessageForJS: (NSString*) message
{
  //    NSString* innerFRame = @"http://example-unstable.hookflash.me/inner.html";
  //    NSString* innerFRame2 = [self.loginIdentity getIdentityLoginURL];
  NSString* jsMethod = [NSString stringWithFormat:@"sendNotifyBundleToInnerFrame(\'%@\')", message];
  [self.webLoginViewController passMessageToJS:jsMethod];;
}

- (void) onLoginRedirectURLReceived
{
    [self.loginIdentity notifyLoginCompleteBrowserWindowRedirection];
}
- (void) makeLoginWebViewVisible:(BOOL) isVisible
{
    self.webLoginViewController.view.hidden = !isVisible;
    if (!self.webLoginViewController.view.superview)
    {
        [[[OpenPeer sharedOpenPeer] mainViewController] showWebLoginView:self.webLoginViewController];
        [self.webLoginViewController.view setFrame:[[OpenPeer sharedOpenPeer] mainViewController].view.bounds];
        //[[[OpenPeer sharedOpenPeer] mainViewController].view addSubview:self.webLoginViewController.view];
    }
}

- (void) onIdentityLoginFinished:(HOPIdentity*) identity
{
    //[[OpenPeerUser sharedOpenPeerUser] setIdentityURI:[self.loginIdentity getIdentityURI]];
    [[[OpenPeerUser sharedOpenPeerUser] dictionaryIdentities] setObject:[identity getIdentityURI] forKey:[identity identityBaseURI]];
    
    [[HOPAccount sharedAccount] loginWithAccountDelegate:(id<HOPAccountDelegate>) [[OpenPeer sharedOpenPeer] accountDelegate] conversationThreadDelegate:(id<HOPConversationThreadDelegate>)[[OpenPeer sharedOpenPeer] conversationThreadDelegate]  callDelegate:(id<HOPCallDelegate>)[[OpenPeer sharedOpenPeer] callDelegate] peerContactServiceDomain:peerContactServiceDomain identity:identity];
    //[[OpenPeerUser sharedOpenPeerUser] setIdentityURI:[identity getIdentityURI]];
    //[[[OpenPeerUser sharedOpenPeerUser] dictionaryIdentities] setObject:[identity getIdentityURI] forKey:[identity identityBaseURI]];
}

- (void) onIdentityassociationFinished:(HOPIdentity*) identity
{
    NSArray* associatedIdentities = [NSArray arrayWithObject:identity];
    [[HOPAccount sharedAccount] associateIdentities:associatedIdentities identitiesToRemove:nil];
}

- (void) sendMessageToJS:(NSString*) message
{
    [self.webLoginViewController passMessageToJS:message];
}
/**
 Handles web view event when OAuth procedure is completed within web view.
 @param url NSString Login URL.
 */
/*
- (void) onCredentialProviderResponseReceived:(NSString*) url
{
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    [xmlWriter writeStartElement:@"result"];
    [xmlWriter writeAttribute:@"xmlns" value:@"http://www.hookflash.com/provisioning/1.0/message"];
    [xmlWriter writeAttribute:@"method" value:@"oauth-login-webpage"];
    [xmlWriter writeAttribute:@"id" value:@"abc"];
    NSArray *array = [url componentsSeparatedByString:@"&"];

    for (NSString* element in array)
    {
        NSArray *attributeValue = [element componentsSeparatedByString:@"="];
        NSString *attribute = [attributeValue objectAtIndex:0];
        NSString *value = [attributeValue objectAtIndex:1];

        if ([attribute isEqualToString:@"properties"])
        {
            NSString *decodedValue = (NSString *) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef) [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], CFSTR(""), kCFStringEncodingUTF8));
            decodedValue = (NSString *) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef) [decodedValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], CFSTR(""), kCFStringEncodingUTF8));
            
            NSString *decodedAccountProperties = [Utility decodeBase64:decodedValue];
            //    result is in format: "stun=173.192.183.148&stun=173.192.183.147&stun=173.192.183.146$turn=173.192.183.146|toto|toto&turn=173.192.183.147|toto4|toto4&turn=173.192.183.148|toto|toto"
            //networkURI=http://bootstrapper.hookflash.me&stun=173.192.183.147&stun=173.192.183.146&stun=173.192.183.148$turn=173.192.183.147|toto2|toto2&turn=173.192.183.148|toto4|toto4&turn=173.192.183.146|toto3|toto3
            [xmlWriter writeStartElement:attribute];
            NSArray *attributeArray = [decodedAccountProperties componentsSeparatedByString:@"&"];
            NSArray *pair = [[attributeArray objectAtIndex:0] componentsSeparatedByString:@"="];
            NSString *propertiesAttribute = [pair objectAtIndex:0];
            NSString *propertiesValue = [pair objectAtIndex:1];
            [xmlWriter writeStartElement:propertiesAttribute];
            [xmlWriter writeCharacters:propertiesValue];
            [xmlWriter writeEndElement];
            
            NSRange replaceRange = [decodedAccountProperties rangeOfString:@"&"];
            NSString *decodedStunsAndTurns = [decodedAccountProperties substringFromIndex:replaceRange.location+1  ];
            
            
            NSArray *stunsAndTurnsArray = [decodedStunsAndTurns componentsSeparatedByString:@"$"];
            
            NSArray *stuns = [[stunsAndTurnsArray objectAtIndex:0] componentsSeparatedByString:@"&"];
            NSArray *turns = [[stunsAndTurnsArray objectAtIndex:1] componentsSeparatedByString:@"&"];
            
            [xmlWriter writeStartElement:@"turnServer"];
            NSString *turnAddressString = @"";
            for (NSString* turn in turns)
            {
                NSString *turnAddressValue = [[[[turn componentsSeparatedByString:@"="] objectAtIndex:1] componentsSeparatedByString:@"|"] objectAtIndex:0];
                if (![turnAddressString isEqualToString:@""])
                {
                    turnAddressString = [turnAddressString stringByAppendingString:@","];
                }
                turnAddressString = [turnAddressString stringByAppendingString:turnAddressValue];
            }
            [xmlWriter writeCharacters:turnAddressString];
            [xmlWriter writeEndElement];
            NSString *turnUsername = [[[turns objectAtIndex:0] componentsSeparatedByString:@"|"] objectAtIndex:1];
            NSString *turnPassword = [[[turns objectAtIndex:0] componentsSeparatedByString:@"|"] objectAtIndex:2];;
            [xmlWriter writeStartElement:@"turnUsername"];
            [xmlWriter writeCharacters:turnUsername];
            [xmlWriter writeEndElement];
            [xmlWriter writeStartElement:@"turnPassword"];
            [xmlWriter writeCharacters:turnPassword];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"stunServer"];
            NSString *stunsString = @"";
            for (NSString* stun in stuns)
            {
                NSString *stunValue = [[stun componentsSeparatedByString:@"="] objectAtIndex:1];
                if (![stunsString isEqualToString:@""])
                {
                    stunsString = [stunsString stringByAppendingString:@","];
                }
                stunsString = [stunsString stringByAppendingString:stunValue];
            }
            [xmlWriter writeCharacters:stunsString];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeEndElement];
        }
        else
        {
            // add key-value
            [xmlWriter writeStartElement:attribute];
            [xmlWriter writeCharacters:value];
            [xmlWriter writeEndElement];
            
            
        }
    }
    [xmlWriter writeEndElement];

    //SDK call to finalize OAuth login process. After returning from webview, XML is formed and information is sent to the SDK to complete login process.
    [[HOPProvisioningAccount sharedProvisioningAccount] completeOAuthLoginProcess:[xmlWriter toString]];
}
*/
/**
 Handles SDK event after login is successful.
 */
- (void) onUserLoggedIn
{
    NSString* uris = @"";
    for (NSString* uri in [[[OpenPeerUser sharedOpenPeerUser] dictionaryIdentities]allValues])
    {
        if ([uris length] == 0)
        {
            uris = uri;
        }
        else
        {
            uris = [uris stringByAppendingFormat:@"%@,",uri];
        }
    }
    NSLog(@"\n ---------- \n%@ is logged in. \nIdentity URIs: %@ \nPeer URI: %@ \n ----------", [[OpenPeerUser sharedOpenPeerUser] fullName],uris,[[OpenPeerUser sharedOpenPeerUser] peerURI]);
    
    //Login finished. Remove activity indicator
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    
    //Save user data on successful login.
    [[OpenPeerUser sharedOpenPeerUser] saveUserData];

    if (self.isLogin)
    {
        self.isLogin = NO;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Identity association" message:@"Do you want to associate another social account" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        
        [alert show];
    }
    else
    {
        //Start loading contacts.
        [[ContactsManager sharedContactsManager] loadContacts];
    }
}

- (void) notifyClient:(NSString*) message
{
    [self.loginIdentity handleMessageFromInnerBrowserWindowFrame:message];
}

- (BOOL) isAssociatedIdentity:(NSString*) inBaseIdentityURI
{
    BOOL ret = [[((OpenPeerUser*)[OpenPeerUser sharedOpenPeerUser]).dictionaryIdentities allKeys] containsObject:inBaseIdentityURI];
    return ret;
}

#pragma UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        self.isAssociation = YES;
        [[[OpenPeer sharedOpenPeer] mainViewController] showLoginView];
    }
    else
    {
        [[ContactsManager sharedContactsManager] loadContacts];
    }
}
@end
