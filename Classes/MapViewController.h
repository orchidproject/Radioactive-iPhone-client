//
//  FirstViewController.h
//  MapAttack
//
//  Created by Aaron Parecki on 2011-08-11.
//  Copyright 2011 Geoloqi.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapAttack.h"
#import "LQConfig.h"
#import "GeoloqiReadClient.h"
#import "sqlite3.h"            // Import SQLITE3 header file


@interface MapViewController : UIViewController <UIWebViewDelegate> {
	UIWebView *webView;
	GeoloqiReadClient *read;
    UILabel *reading;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIView *activityIndicator;
@property (nonatomic, retain) IBOutlet UILabel *reading;
- (void)setClientStatus;

-(IBAction) read:(id)sender;
-(IBAction) logout:(id)sender;
-(IBAction) investigate:(id)sender;

- (void)loadURL:(NSString *)url;
- (void)loadBlank;


@end
