//
//  LQClient.h
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-31.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

static NSString *const LQBeginJoinGameNotification= @"LQBeginJoinGameNotification";
static NSString *const LQAuthenticationFailedNotification = @"LQAuthenticationFailedNotification";
static NSString *const LQAccessTokenKey = @"LQAccessToken";
static NSString *const LQAuthEmailAddressKey = @"LQAuthEmailAddressKey";
static NSString *const LQAuthInitialsKey = @"LQAuthInitialsKey";
static NSString *const LQAuthUserIDKey = @"LQAuthUserIDKey";
static NSString *const LQAuthTeamKey = @"LQAuthTeamKey";


//static NSString *const LQAPIBaseURL = @"http://holt.mrl.nott.ac.uk:49992/";
static NSString *const LQAPIBaseURL = @"http://10.0.2.60:49992/";

typedef void (^LQHTTPRequestCallback)(NSError *error, NSDictionary *response);

@interface LQClient : NSObject {
//	NSMutableArray *queue;
//	ASIHTTPRequest *authenticationRequest;
    CLLocation *location;
    NSString *currentLayerId;
    NSString *gameID;
    bool isLogin;
}


@property (nonatomic, copy) CLLocation *location;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *userInitials;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *gameID;
@property (nonatomic, copy) NSString *team;

@property (nonatomic, copy) NSString *shareToken;

+ (LQClient *)single;
- (BOOL)isLoggedIn;
// - (NSString *)refreshToken;
- (void)sendPushToken:(NSString *)token withCallback:(LQHTTPRequestCallback)callback;
- (void)getNearbyLayers:(CLLocation *)location withCallback:(LQHTTPRequestCallback)callback;
- (void)getPlaceContext:(CLLocation *)location withCallback:(LQHTTPRequestCallback)callback;
//- (void)createNewAccountWithEmail:(NSString *)email initials:(NSString *)initials callback:(LQHTTPRequestCallback)callback;
- (void)joinGame:(NSString *)layer_id  withCallback:(LQHTTPRequestCallback)callback;
- (void)logout;
- (void)getReadingWithCallback:(LQHTTPRequestCallback)callback;
- (void)investigateWithCallback:(LQHTTPRequestCallback)callback;
@end

