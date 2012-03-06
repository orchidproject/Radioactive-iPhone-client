//
//  FirstViewController.m
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-11.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import "MapViewController.h"
#import "CJSONSerializer.h"
#import "LQClient.h"
#import "AuthView.h"
#import "MapAttackAppDelegate.h"



@implementation MapViewController

@synthesize webView, activityIndicator, reading;
  


-(IBAction) read:(id)sender{
    //send read request here
    CLLocation *location=[LQClient single].location;
    if(location==nil){
        return;
    }
    else{
        [[LQClient single] getReadingWithCallback:^(NSError *error, NSDictionary *response){
            DLog(@"getReading: %@", response);
            reading.text=[NSString stringWithFormat:@"Reading:%@", [response valueForKey:@"reading"]];
        }];

    }
                     
}

-(IBAction) logout:(id)sender{
    [[LQClient single] logout];
}

-(IBAction) investigate:(id)sender{
    //send read request here
    CLLocation *location=[LQClient single].location;
    if(location==nil){
        return;
    }
    else{
        [[LQClient single] investigateWithCallback:^(NSError *error, NSDictionary *response){
            DLog(@"investigate result: %@", response);
            //reading.text=[NSString stringWithFormat:@"Reading:%@", [response valueForKey:@"reading"]];
        }];
        
    }
    
}
/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void)loadURL:(NSString *)url {
	// If we don't have authentication tokens here, then pop up the login page to get their email and initials
	if(![[LQClient single] isLoggedIn]) {
		[lqAppDelegate.tabBarController presentModalViewController:[[AuthView alloc] init] animated:YES];
	} else {
		//[webView loadRequest:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[url stringByAppendingFormat:@"?access_token=%@&user_id=%@&team=%@", [[LQClient single] accessToken], [[LQClient single] userID], [[LQClient single] team]]]]];
        [webView loadRequest:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[url stringByAppendingFormat:@"?id=%@", [[LQClient single] userID] ]]]];
		//[lqAppDelegate.read reconnect];
		DLog(@"Loading URL in game view %@", [url stringByAppendingFormat:@"?id=%@", [[LQClient single] userID]  ]);
        //[lqAppDelegate.tabBarController presentModalViewController:[[WaitingRoomView alloc] init] animated:NO];
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	

    //	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:LQMapAttackWebURL]]];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mapAttackDataBroadcastReceived:)
												 name:LQMapAttackDataNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(locationUpdateReceived:)
												 name:LQLocationUpdateManagerDidUpdateLocationNotification
											   object:nil];
}

- (void)loadBlank{
    
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"BlankGame" ofType:@"html"]isDirectory:NO]]];
}


- (void)locationUpdateReceived:(NSNotification *)notification{
    
    DLog(@"%@",[NSString stringWithFormat:@"if(typeof locationUpdate != \"undefined\") { locationUpdate(%@,%f,%f); }", [LQClient single].userID,[LQClient single].location.coordinate.latitude,[LQClient single].location.coordinate.longitude ]);
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(typeof locationUpdate != \"undefined\") { locationUpdate(%@,%f,%f); }", [LQClient single].userID,[LQClient single].location.coordinate.latitude,[LQClient single].location.coordinate.longitude ]];
    
}


- (void)mapAttackDataBroadcastReceived:(NSNotification *)notification {
	DLog(@"got data broadcast");
	
    DLog(@"%@", [NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
				  "LQHandlePushData(%@); }", [[notification userInfo] objectForKey:@"json"]]);
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
													 "LQHandlePushData(%@); }", [[notification userInfo] objectForKey:@"json"]]];
	

//	an example for sending json
//	DLog(@"%@", [NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
//		   "LQHandlePushData(%@); }", [[CJSONSerializer serializer] serializeDictionary:[notification userInfo]]]);
//	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(typeof LQHandlePushData != \"undefined\") { "
//													 "LQHandlePushData(%@); }", [[CJSONSerializer serializer] serializeDictionary:[notification userInfo]]]];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

/*
- (void)zoomMapToLocation:(CLLocation *)location
{
    MKCoordinateSpan span;
    span.latitudeDelta  = 0.03;
    span.longitudeDelta = 0.03;
    
    MKCoordinateRegion region;
    
    [map setCenterCoordinate:location.coordinate animated:YES];
    
    region.center = location.coordinate;
    region.span   = span;
    
    [map setRegion:region animated:YES];
}

- (IBAction)tappedLocate:(id)sender
{
    CLLocation *location;
    
	//    if(location = [[Geoloqi sharedInstance] currentLocation])
	//    {
	//        [self zoomMapToLocation:location];
	//    }
	//    else if(mapView.userLocationVisible)
	//    {
	location = map.userLocation.location;
	[self zoomMapToLocation:location];
	//    }
}
*/

- (void)setClientStatus:(NSString*) query{
    
    NSArray *arr=[query componentsSeparatedByString:@"&"];
    [LQClient single].userID=[arr objectAtIndex:0];
    [LQClient single].team=[arr objectAtIndex:1];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Do you want to say hello?" message: [LQClient single].userID delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Say Hello",nil];
    [alert show];
    [alert release];

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([[[request URL] scheme] isEqualToString:@"myapp"]) { 
        /*SEL selector = NSSelectorFromString([[request URL] query]);
        if([self respondsToSelector:selector]) {
            [self performSelector:selector];
        } else {
            //alert user of invalid URL
        }*/
       
        if([[[request URL] path] isEqualToString:@"/start"]){
            //[self setClientStatus:[[request URL] query]] ;
        };
        
        if([[[request URL] path] isEqualToString:@"/end"]){
            //[self setClientStatus:[[request URL] query]] ;
        };
        
        if([[[request URL] path] isEqualToString:@"/reset"]){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message: @"Game has been reset" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];
            [alert release];
            
            [[LQClient single] logout];
            [lqAppDelegate.tabBarController  setSelectedIndex:0];
        };
        return NO;
    }
    return YES;
}



- (void)webViewDidFinishLoad:(UIWebView *)w {
	self.activityIndicator.alpha = 0.0;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {     
	self.activityIndicator.alpha = 1.0;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	//[read disconnect];
}


- (void)dealloc {
	[webView release];
    [super dealloc];
    [reading dealloc];
}

@end
