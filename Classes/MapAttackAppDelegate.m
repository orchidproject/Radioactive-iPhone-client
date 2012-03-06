//
//  MapAttackAppDelegate.m
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-11.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import "MapAttackAppDelegate.h"
#import "CJSONSerializer.h"


MapAttackAppDelegate *lqAppDelegate;

@implementation MapAttackAppDelegate

@synthesize window;
@synthesize tabBarController, authViewController, logListView;
@synthesize geoloqi;
@synthesize mapController;
@synthesize socketClient;
@synthesize read;

#pragma mark Application launched
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	lqAppDelegate = self;
    tabBarController.delegate=self;
	DLog(@"App Launch %@", launchOptions);

    // Override point for customization after application launch.

    // Add the tab bar controller's view to the window and display.
    [self.window addSubview:tabBarController.view];
    [self.window makeKeyAndVisible];

	[MapAttackAppDelegate UUID];
	
	socketClient = [[GeoloqiSocketClient alloc] init];
    read = [[GeoloqiReadClient alloc] init];
	self.geoloqi = [[LQClient alloc] init];

	if([[LQClient single] isLoggedIn]) {
		// Start sending location updates
		// [socketClient startMonitoringLocation];

		[[UIApplication sharedApplication]
		 registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
											 UIRemoteNotificationTypeSound |
											 UIRemoteNotificationTypeAlert)];
	} else {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(authenticationDidSucceed:)
													 name:LQBeginJoinGameNotification
												   object:nil];
	}
    // Reachability notification for network connectivity   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNetworkChange:)
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    socketReadReachability = [[Reachability reachabilityForInternetConnection] retain];
    [socketReadReachability startNotifier];
    
    // [self clearLog];
    //setup timer for logging
    [NSTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                   selector:@selector(saveLog)
                                   userInfo:nil
                                    repeats:YES];
    [self writeBatteryLevel];
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(writeBatteryLevel)
                                   userInfo:nil
                                    repeats:YES];
    
    
    //[self addLog:@"haha"];
    return YES;
}

-(void)handleNetworkChange:(NSNotification *) notice
{
    Reachability *r = [notice object];
    NetworkStatus remoteHostStatus = r.currentReachabilityStatus;
    if(remoteHostStatus == NotReachable) 
    {
        DLog(@"No Network Connectivity (printed from file MapViewController.m)");
        [self writeToLog:@"No Network Connectivity"];
    }
    else if(remoteHostStatus == ReachableViaWiFi || remoteHostStatus == ReachableViaWWAN)
    {
        DLog(@"Network connectivity detected"); 
        [self writeToLog:@"Network connectivity detected"];
    }
}

#pragma mark Logged in Successfully
- (void)authenticationDidSucceed:(NSNotificationCenter *)notification
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    //name:LQAuthenticationSucceededNotification 
                                                  //object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self 
//                                                    name:LQAuthenticationFailedNotification 
//                                                  object:nil];
	
	//geoloqi = [[GeoloqiSocketClient alloc] init];
    if (tabBarController.modalViewController && [tabBarController.modalViewController isKindOfClass:[authViewController class]])
        [tabBarController dismissModalViewControllerAnimated:YES];
    
   
	
    // Register for push notifications after logging in successfully
	[[UIApplication sharedApplication]
	 registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
										 UIRemoteNotificationTypeSound |
										 UIRemoteNotificationTypeAlert)];
	
	//[self.mapController loadURL:@""];
	
	// Start sending location updates
	//[socketClient startMonitoringLocation];
}

#pragma mark Push token registered
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)_deviceToken {
    // Get a hex string from the device token with no spaces or < >
    deviceToken = [[[[_deviceToken description]
					 stringByReplacingOccurrencesOfString: @"<" withString: @""] 
					stringByReplacingOccurrencesOfString: @">" withString: @""] 
				   stringByReplacingOccurrencesOfString: @" " withString: @""];
	
	DLog(@"Device Token: %@", deviceToken);
	
	[[LQClient single] sendPushToken:deviceToken withCallback:^(NSError *error, NSDictionary *response){
		DLog(@"Sent device token: %@", response);
	}];
	
	if ([application enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone) {
		DLog(@"Notifications are disabled for this application. Not registering.");
		return;
	}
}

#pragma mark Received push notification
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	DLog(@"Received Push! %@", userInfo);
	
	// Push was received while the app was in the foreground
	if(application.applicationState == UIApplicationStateActive) {
		NSDictionary *data = [userInfo valueForKeyPath:@"mapattack"];
		if(data) {
			DLog(@"Got some location data! Yeah!!");
			
			// The data in the push notification is already an NSDictionary, we need to serialize it to JSON
			// format to pass to the web view.
			
			NSDictionary *json = [NSDictionary dictionaryWithObject:[[CJSONSerializer serializer] serializeObject:userInfo] forKey:@"json"];
			[[NSNotificationCenter defaultCenter] postNotificationName:LQMapAttackDataNotification
																object:self
															  userInfo:json];
			return;
		}
	}
	
}

#pragma mark -

-(void)loadGameWithURL:(NSString *)url {
	[tabBarController setSelectedIndex:1];
	DLog(@"MapAttackAppDelegate loadGameWithURL:%@", url);
    [socketClient startMonitoringLocation];
	[self.mapController loadURL:url];
}

-(void)cleanUpMap {
	[tabBarController setSelectedIndex:0];
	[socketClient stopMonitoringLocation];
	
}



#pragma mark -
#pragma mark Application lifecycle

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark UITabBarControllerDelegate methods


// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if(viewController==mapController){
        if(![[LQClient single] isLoggedIn])
        {
            [mapController loadBlank];
        }
    }
    else if(viewController==logListView){
        [logListView.tableView reloadData];
    }
       
    
}


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}



#pragma mark core data

#pragma mark Core Data stack setup

//
// These methods are very slightly modified from what is provided by the Xcode template
// An overview of what these methods do can be found in the section "The Core Data Stack" 
// in the following article: 
// http://developer.apple.com/iphone/library/documentation/DataManagement/Conceptual/iPhoneCoreData01/Articles/01_StartingOut.html
//

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator == nil) {
        NSURL *storeUrl = [NSURL fileURLWithPath:self.persistentStorePath];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
        NSError *error = nil;
        NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];
        
        
    }
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext == nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return managedObjectContext;
}

- (NSString *)persistentStorePath {
    if (persistentStorePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths lastObject];
        persistentStorePath = [[documentsDirectory stringByAppendingPathComponent:@"MapAttack.sqlite"] retain];
    }
    return persistentStorePath;
}

-(void)saveLog{
    if ([LQClient single].gameID==nil || [LQClient single].userID==nil ) {
        return;
    }
    //fetch
     NSFetchRequest *request = [[NSFetchRequest alloc] init];
     NSEntityDescription *entity = [NSEntityDescription entityForName:@"Log" inManagedObjectContext:[self managedObjectContext]];
     [request setEntity:entity];
    
     /*NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(game_id MATCHES %@) AND (player_id MATCHES %@)",[LQClient single].userID ,[LQClient single].gameID];
     [request setPredicate:predicate];*/
     
     NSError *error = nil;
     NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
     if (mutableFetchResults == nil) {
         [self alert:@"error"];
     }
     
     NSManagedObject *log= nil;
    
    for(NSManagedObject * obj in mutableFetchResults){
        if([(NSString *)[obj valueForKey:@"game_id"] isEqualToString:[LQClient single].gameID] && [(NSString *)[obj valueForKey:@"player_id"] isEqualToString:[LQClient single].userID])
        {
            log=obj;
            break;
        }
        
    }
    
     if(log == nil){
        log = [[NSEntityDescription insertNewObjectForEntityForName:@"Log" inManagedObjectContext:self.managedObjectContext] retain];
        [log setValue:[NSDate date] forKey:@"created_at"];
        [log setValue:[LQClient single].gameID forKey:@"game_id"];
        [log setValue:[LQClient single].userID  forKey:@"player_id"];
         //[log setValue:@"a" forKey:@"game_id"];
         //[log setValue:@"a" forKey:@"player_id"];
     }else{
        [log retain];
     
     }
     
     [mutableFetchResults release];
     [request release];
    
    NSString *original_string=[log valueForKey:@"content"];
    if(original_string==nil){
        original_string=@"";
    }
    log_string=[NSString stringWithFormat:@"%@%@",original_string,log_string];
    [log setValue:log_string forKey:@"content"];
    [log setValue:[NSDate date] forKey:@"updated_at"];
    
    
    error = nil;
    if (![self.managedObjectContext save:&error]) {
        [self alert:@"error"];
    }
    //[self alert:log_string];
    log_string=nil;
    
    [log release];
    
}
-(void)writeToLog:(NSString *)string{
    if ([LQClient single].gameID==nil || [LQClient single].userID==nil ) {
        return;
    }
    if(log_string==nil){
        log_string=@"";
    }
    else{
        //[log_string release];
        
    }
    NSString *temp=log_string;
    log_string=[[NSString alloc ]initWithFormat:@"%@\n%f:%@",log_string,[[NSDate date] timeIntervalSince1970],string];
    [temp release];
    
    
    
}

-(NSMutableArray *)getLogs{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Log" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];
    
    /*NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(game_id MATCHES %@) AND (player_id MATCHES %@)",[LQClient single].userID ,[LQClient single].gameID];
     [request setPredicate:predicate];*/
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        [self alert:@"error"];
    }
    
    return mutableFetchResults;
}

-(void)writeBatteryLevel{
   
    
    UIDevice *device=[UIDevice currentDevice];
    [device setBatteryMonitoringEnabled:YES];
    int batteryLevel=[device batteryLevel]*100;
    [self writeToLog:[NSString stringWithFormat:@"battery %d",batteryLevel]];

    
    
}


-(void)clearLog{
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Log" inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        [self alert:@"error"];
    }
    
    for( NSManagedObject * obj in mutableFetchResults){
        [[self managedObjectContext] deleteObject:obj];
    }
    
    if (![managedObjectContext save:&error]) {
        // Handle the error.
    }
    
    [mutableFetchResults release];
    [request release];
    
}

-(void)alert:(NSString*) massage{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"problem" message: massage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
    [alert release];
    
}


#pragma mark -


+ (NSData *)UUID {
	if([[NSUserDefaults standardUserDefaults] dataForKey:LQUUIDKey] == nil) {
		CFUUIDRef theUUID = CFUUIDCreate(NULL);
		CFUUIDBytes bytes = CFUUIDGetUUIDBytes(theUUID);
		NSData *dataUUID = [NSData dataWithBytes:&bytes length:sizeof(CFUUIDBytes)];
		CFRelease(theUUID);
		[[NSUserDefaults standardUserDefaults] setObject:dataUUID forKey:LQUUIDKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		DLog(@"Generating new UUID: %@", dataUUID);
		return dataUUID;
	} else {
		DLog(@"Returning existing UUID: %@", [[NSUserDefaults standardUserDefaults] dataForKey:LQUUIDKey]);
		return [[NSUserDefaults standardUserDefaults] dataForKey:LQUUIDKey];
	}
}

- (void)dealloc {
	[geoloqi release];
	[socketClient release];
    [tabBarController release];
    [window release];
    [read release];
    [socketReadReachability release];
    [super dealloc];
}

@end

