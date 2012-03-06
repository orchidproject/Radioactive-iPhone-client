//
//  MapAttackAppDelegate.h
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-11.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "GeoloqiSocketClient.h"
#import "MapAttack.h"
#import "LQClient.h"
#import "AuthView.h"
#import "MapViewController.h"
#import "Reachability.h"



static NSString *const LQUUIDKey = @"LQUUID";

@interface MapAttackAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;
	GeoloqiSocketClient *socketClient;
    UITableViewController *logListView;
	LQClient *geoloqi;
	NSString *deviceToken;
    GeoloqiReadClient *read;
    Reachability *socketReadReachability;
    
    
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSString *persistentStorePath;
    
    NSString *log_string;
}

@property (nonatomic, retain) GeoloqiSocketClient *socketClient;
@property (nonatomic, retain) GeoloqiReadClient *read;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AuthView *authViewController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet UITableViewController *logListView;
@property (nonatomic, retain) LQClient *geoloqi;
@property (nonatomic, retain) IBOutlet MapViewController *mapController;

+(NSData *)UUID;
-(void)loadGameWithURL:(NSString *)url;
-(void)cleanUpMap;

- (void)alert;
-(void)saveLog;
-(void)alert:(NSString*) massage;
-(void)clearLog;
-(void)writeToLog:(NSString *)string;
-(void)writeBatteryLevel;
-(NSMutableArray *)getLogs;

//core data
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSString *persistentStorePath;

@end

extern MapAttackAppDelegate *lqAppDelegate;
