//
//  LQClient.m
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-31.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import "LQClient.h"
#import "LQConfig.h"
#import "MapAttack.h"
#import "CJSONDeserializer.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "MapAttackAppDelegate.h"

static NSString *const LQClientRequestNeedsAuthenticationUserInfoKey = @"LQClientRequestNeedsAuthenticationUserInfoKey";

@implementation LQClient

@synthesize shareToken,location,gameID;

+ (LQClient *)single {
	static LQClient *singleton = nil;
    if(!singleton) {
		singleton = [[self alloc] init];
	}
	return singleton;
}

- (id) init
{
    self = [super init];
    isLogin=NO;
	if(!self) return nil;

//	queue = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc {
	[super dealloc];
}

/**
 * Getter/setter for accessToken key, uses NSUserDefaults for permanent storage.
 */
- (NSString *)accessToken {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQAccessTokenKey];
}
- (void)setAccessToken:(NSString *)token {
	[[NSUserDefaults standardUserDefaults] setObject:[[token copy] autorelease] forKey:LQAccessTokenKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)emailAddress {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQAuthEmailAddressKey];
}
- (void)setEmailAddress:(NSString *)email {
	[[NSUserDefaults standardUserDefaults] setObject:[[email copy] autorelease] forKey:LQAuthEmailAddressKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userInitials {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQAuthInitialsKey];
}
- (void)setUserInitials:(NSString *)initials {
	[[NSUserDefaults standardUserDefaults] setObject:[[initials copy] autorelease] forKey:LQAuthInitialsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userID {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQAuthUserIDKey];
}
- (void)setUserID:(NSString *)uid {
	[[NSUserDefaults standardUserDefaults] setObject:[[uid copy] autorelease] forKey:LQAuthUserIDKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)team {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQAuthTeamKey];
}
- (void)setTeam:(NSString *)team_name {
	[[NSUserDefaults standardUserDefaults] setObject:[[team_name copy] autorelease] forKey:LQAuthTeamKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (ASIHTTPRequest *)appRequestWithURL:(NSURL *)url {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUsername:LQ_OAUTH_CLIENT_ID];
	[request setPassword:LQ_OAUTH_SECRET];
	return request;
}

- (ASIHTTPRequest *)appRequestWithURL:(NSURL *)url class:(NSString *)class {
	ASIHTTPRequest *request = [NSClassFromString(class) requestWithURL:url];
	[request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUsername:LQ_OAUTH_CLIENT_ID];
	[request setPassword:LQ_OAUTH_SECRET];
	return request;
}

- (ASIHTTPRequest *)userRequestWithURL:(NSURL *)url {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
//  This is a old geolqi stuff
//	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"OAuth %@", self.accessToken]];
//	NSMutableDictionary *dict = (request.userInfo ? [[NSMutableDictionary alloc] initWithDictionary:request.userInfo] : [[NSMutableDictionary alloc] init]);
//	request.userInfo = dict;
//	[dict setObject:[NSNumber numberWithBool:YES] forKey:LQClientRequestNeedsAuthenticationUserInfoKey];
    
	return request;
}

- (ASIHTTPRequest *)userRequestWithURL:(NSURL *)url class:(NSString *)class {
	ASIHTTPRequest *request = [NSClassFromString(class) requestWithURL:url];
	[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"OAuth %@", self.accessToken]];
	return request;
}

- (NSDictionary *)dictionaryFromResponse:(NSString *)response {
	NSError *err = nil;
	NSDictionary *res = [[CJSONDeserializer deserializer] deserializeAsDictionary:[response dataUsingEncoding:NSUTF8StringEncoding] error:&err];
	return res;
}

- (NSURL *)urlWithPath:(NSString *)path {
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", LQAPIBaseURL, path]];
}

- (NSString *)hardware
{
	size_t size;
	
	// Set 'oldp' parameter to NULL to get the size of the data
	// returned so we can allocate appropriate amount of space
	sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
	
	// Allocate the space to store name
	char *name = malloc(size);
	
	// Get the platform name
	sysctlbyname("hw.machine", name, &size, NULL, 0);
	
	// Place name into a string
	NSString *machine = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
	
	// Done with this
	free(name);
	
	return machine;
}

/*
// This was for queuing/dequeuing requests so we could refresh the access token if necessary
- (void)dequeueUserRequestIfPossible {
	if(queue.count > 0 && self.accessToken) {
		ASIHTTPRequest *request = (ASIHTTPRequest *)[queue objectAtIndex:0];
		[request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"OAuth %@", @"xxx"]];
		[request startAsynchronous];
		[queue removeObjectAtIndex:0];
	} else if(!authenticationRequest) {
		__block ASIFormDataRequest *request = [self appRequestWithURL:[self urlWithPath:@"oauth/token"] class:@"ASIFormDataRequest"];
		[request setPostValue:@"refresh_token" forKey:@"grant_type"];
		[request setPostValue:[self refreshToken] forKey:@"refresh_token"];
		[request setCompletionBlock:^{
			NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
			// Store access token
			self.accessToken = (NSString *)[responseDict objectForKey:@"access_token"];
			[authenticationRequest release];
			authenticationRequest = nil;
			[self dequeueUserRequestIfPossible];
		}];
		authenticationRequest = [request retain];
	}
}

- (void)enqueueUserRequest:(ASIHTTPRequest *)inRequest {
	__block ASIHTTPRequest *request = inRequest;
	[request setCompletionBlock:^{
		if (request.completionBlock)
			request.completionBlock();
		[self dequeueUserRequestIfPossible];
	}];
	[queue addObject:request];
	[self dequeueUserRequestIfPossible];
}
*/

- (void)runRequest:(ASIHTTPRequest *)inRequest callback:(LQHTTPRequestCallback)callback {
	__block ASIHTTPRequest *request = inRequest;
	[request setCompletionBlock:^{
		callback(nil, [self dictionaryFromResponse:[request responseString]]);
	}];
	[request setFailedBlock:^{
		DLog(@"Request Failed %@", request);
		callback(request.error, nil);
	}];
	[request startAsynchronous];
}

- (void)createShareToken {
//	NSURL *url = [self urlWithPath:@"link/create"];
//	__block ASIFormDataRequest *request = (ASIFormDataRequest *)[self userRequestWithURL:url class:@"ASIFormDataRequest"];
//	[request setPostValue:@"Testing for MapAttack" forKey:@"description"];
//	[self runRequest:request callback:^(NSError *error, NSDictionary *response){
//		self.shareToken = [response objectForKey:@"shortlink"];
//		DLog(@"Token: %@", response);
//	}];
}

#pragma mark public methods

- (BOOL)isLoggedIn {
	DLog(@"Is logged in? %@", self.accessToken);
	return isLogin;
}

/*
- (NSString *)refreshToken {
	return [[NSUserDefaults standardUserDefaults] stringForKey:LQRefreshTokenKey];
}
*/

- (void)addDeviceInfoToRequest:(ASIFormDataRequest *)request {
	UIDevice *d = [UIDevice currentDevice];
	[request setPostValue:[NSString stringWithFormat:@"%@ %@", d.systemName, d.systemVersion] forKey:@"platform"];
	[request setPostValue:[self hardware] forKey:@"hardware"];
	const unsigned *tokenBytes = [[MapAttackAppDelegate UUID] bytes];
	NSString *hexDeviceID = [NSString stringWithFormat:@"%08x%08x%08x%08x",
							 ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]), ntohl(tokenBytes[3])];	
	[request setPostValue:hexDeviceID forKey:@"device_id"];
}

/*- (void)createNewAccountWithEmail:(NSString *)email initials:(NSString *)initials  callback:(LQHTTPRequestCallback)callback {
    
    
	NSURL *url = [self urlWithPath:@"create/player/runner"];
	__block ASIFormDataRequest *request = (ASIFormDataRequest *)[self appRequestWithURL:url class:@"ASIFormDataRequest"];

	[request setPostValue:initials forKey:@"name"];
    [request setPostValue:email forKey:@"email"];

	//[self addDeviceInfoToRequest:request];
	
	[request setCompletionBlock:^{
		NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
		self.emailAddress = email;
		self.userInitials = initials;
        NSString *userID = nil;
        userID=(NSString *)[responseDict objectForKey:@"player_id"];
        if (userID != nil){
            isLogin=YES;self.userID = (NSString *)[responseDict objectForKey:@"player_id"];
            callback(nil, responseDict);
            NSLog(@"playerID recieved %@", [responseDict description]);
        }
		
        //self.accessToken = (NSString *)[responseDict objectForKey:@"access_token"];  // this runs synchronize
		// [[NSUserDefaults standardUserDefaults] setObject:(NSString *)[responseDict objectForKey:@"refresh_token"] forKey:LQRefreshTokenKey];
		//[self createShareToken];
	}];
	[request startAsynchronous];
     
}*/

- (void)getReadingWithCallback:(LQHTTPRequestCallback)callback{
    DLog(@"request reading");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:MapAttackGetReadingURLFormat, currentLayerId]];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    NSString *slatitude= [NSString stringWithFormat:@"%f",location.coordinate.latitude];
    NSString *slongitude= [NSString stringWithFormat:@"%f",location.coordinate.longitude];
    [request setPostValue:slatitude forKey:@"latitude"];
    [request  setPostValue:slongitude forKey:@"longitude"];
    [request setPostValue:self.userID forKey:@"id"];
    
    [request setCompletionBlock:^{
		NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
		DLog(@"Response from mapattack.org %@", [request responseString]);
		self.team = (NSString *)[responseDict objectForKey:@"team_name"];
		callback(nil, responseDict);
	}];
	[request startAsynchronous];
    
}

- (void)investigateWithCallback:(LQHTTPRequestCallback)callback{
    DLog(@"request reading");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:MapAttackInvestigateURLFormat, currentLayerId]];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    NSString *slatitude= [NSString stringWithFormat:@"%f",location.coordinate.latitude];
    NSString *slongitude= [NSString stringWithFormat:@"%f",location.coordinate.longitude];
    [request setPostValue:slatitude forKey:@"latitude"];
    [request  setPostValue:slongitude forKey:@"longitude"];
    [request setPostValue:self.userID forKey:@"id"];
    
    [request setCompletionBlock:^{
        NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
		DLog(@"Response from mapattack.org %@", [request responseString]);
		//self.team = (NSString *)[responseDict objectForKey:@"team_name"];
		callback(nil, responseDict);
    
    }];
	[request startAsynchronous];
}

- (void)joinGame:(NSString *)layer_id withCallback:(LQHTTPRequestCallback)callback {
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:MapAttackJoinURLFormat, layer_id]];
	DLog(@"Joining game... %@", url);
	__block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
   
	[request setPostValue:self.userInitials forKey:@"name"];
	[request setPostValue:self.emailAddress forKey:@"email"];
	//[request setPostValue:self.userID forKey:@"id"];
    
    //team selection in games
    [request setPostValue:@"runner" forKey:@"team_name"];
    
    
	[request setCompletionBlock:^{
		NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
		DLog(@"Response from mapattack.org %@", [request responseString]);
        self.userID = (NSString *)[responseDict objectForKey:@"user_id"];
		self.team = (NSString *)[responseDict objectForKey:@"team_name"];
        
        if (self.userID!=nil){
           isLogin=YES;
        }
        else{
            
            NSString *errstr = (NSString *)[responseDict objectForKey:@"error"];
            if (errstr!= nil) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errstr message: @"Try refresh list" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        }
		callback(nil, responseDict);
        currentLayerId=layer_id;
	}];
	[request startAsynchronous];
}







- (void)sendPushToken:(NSString *)token withCallback:(LQHTTPRequestCallback)callback {
	// TODO: Send this device token to the Geoloqi API
	NSURL *url = [self urlWithPath:@"account/set_apn_token"];
	DLog(@"Sending push token %@ to %@", token, url);
	__block ASIFormDataRequest *request = (ASIFormDataRequest *)[self userRequestWithURL:url class:@"ASIFormDataRequest"];
	[self addDeviceInfoToRequest:request];
	[request setPostValue:token forKey:@"token"];
	[self runRequest:request callback:callback];
}

- (void)getNearbyLayers:(CLLocation *)location withCallback:(LQHTTPRequestCallback)callback {
	NSURL *url = [self urlWithPath:@"games/list"];
    __block ASIHTTPRequest *request;
    request = [ASIHTTPRequest requestWithURL:url];
	[self runRequest:request callback:callback];

}

- (void)getPlaceContext:(CLLocation *)location withCallback:(LQHTTPRequestCallback)callback {
	NSURL *url = [self urlWithPath:[NSString stringWithFormat:@"location/context?latitude=%f&longitude=%f", 
									//45.5246, -122.6843, MapAttackAppID]];
									location.coordinate.latitude, location.coordinate.longitude]];
	__block ASIHTTPRequest *request;
	if([self isLoggedIn]) {
		request = [self userRequestWithURL:url];
	} else {
		request = [self appRequestWithURL:url];
	}
	[self runRequest:request callback:callback];
}

- (void)logout {
    
    DLog(@"logging out");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:MapAttackLogoutURLFormat, currentLayerId]];
    DLog(@"%@", [NSString stringWithFormat:MapAttackLogoutURLFormat, currentLayerId]);
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:self.userID forKey:@"id"];
    
    [request setCompletionBlock:^{
		//NSDictionary *responseDict = [self dictionaryFromResponse:[request responseString]];
		DLog(@"Response from server %@", [request responseString]);
	}];
    
	[request startAsynchronous];
    [lqAppDelegate cleanUpMap];
    
    isLogin=NO;
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAuthEmailAddressKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAuthInitialsKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAuthTeamKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAuthUserIDKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LQAccessTokenKey];
	self.accessToken = nil;
}

@end


